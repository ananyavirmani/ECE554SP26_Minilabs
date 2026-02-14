module image_processing_module (
    input iCLK,
    input iRST,
    input [11:0] iDATA,
    input iDVAL,
    output [11:0] oRed,
    output [11:0] oGreen,
    output [11:0] oBlue,
    output oDVAL,
    input [10:0] iX_Cont,
    input [10:0] iY_Cont
);

logic [11:0] mDATA_0, mDATA_1;
logic [11:0] mDATAd_0, mDATAd_1;
logic [13:0] gray,gray_scale;
logic mDVAL;

logic [11:0] gray_pixel;
logic [11:0] gDATA_0, gDATA_1;

logic [15:0] mag;
logic window_valid;

assign gray_pixel = gray_scale[13:2];
assign mDATA_0 = iDATA;

Line_Buffer1 u0(
    .clken(iDVAL),
    .clock(iCLK),
    .shiftin(iDATA),
    .taps0x(mDATA_1),  // single row delay (1280 pixels) for 2x2 neighborhood
    .taps1x()
);


assign oRed = mag[15:4]; // example: output edge magnitude as red; adjust bit slicing as needed
assign oGreen = mag[15:4];
assign oBlue = mag[15:4];
assign oDVAL = window_valid;



always @(posedge iCLK or negedge iRST) begin
    if (!iRST) begin
        mDATAd_0 <= 0;
        mDATAd_1 <= 0;
        mDVAL <= 0;
    end else begin
        mDATAd_0 <= mDATA_0;
        mDATAd_1 <= mDATA_1;
        mDVAL <= {iY_Cont[0] | iX_Cont[0]} ? 1'b0 : iDVAL;
        gray_scale <= mDATA_0 + mDATA_1 + mDATAd_0 + mDATAd_1;
    end
end


// three-stage shift for current row
logic [11:0] cur_s0, cur_s1, cur_s2;
always @(posedge iCLK or negedge iRST) begin
  if (!iRST) {cur_s0,cur_s1,cur_s2} <= 0;
  else if (mDVAL) begin
    cur_s0 <= gray_pixel;    // newest (rightmost)
    cur_s1 <= cur_s0;        // center
    cur_s2 <= cur_s1;        // leftmost
  end
end

// two line buffers: store previous rows of grayscale
logic [11:0] row1_tap0, row1_tap1; // taps from first line-buffer
logic [11:0] row2_tap0, row2_tap1; // taps from second line-buffer
Line_Buffer1 lb1 (
  .clken(mDVAL),
  .clock(iCLK),
  .shiftin(gray_pixel),
  .taps0x(row1_tap1),
  .taps1x(row1_tap0)
);
// chain second line buffer: feed it with the same column from row1
Line_Buffer1 lb2 (
  .clken(mDVAL),
  .clock(iCLK),
  .shiftin(row1_tap0),
  .taps0x(row2_tap1),
  .taps1x(row2_tap0)
);

// 3-stage shift for previous rows (align columns)
logic [11:0] r1_s0, r1_s1, r1_s2;
logic [11:0] r2_s0, r2_s1, r2_s2;
always @(posedge iCLK or negedge iRST) begin
  if (!iRST) begin
    {r1_s0,r1_s1,r1_s2} <= 0;
    {r2_s0,r2_s1,r2_s2} <= 0;
  end else if (mDVAL) begin
    r1_s0 <= row1_tap0; r1_s1 <= r1_s0; r1_s2 <= r1_s1;
    r2_s0 <= row2_tap0; r2_s1 <= r2_s0; r2_s2 <= r2_s1;
  end
end

// assemble 3x3 neighborhood (a00 top-left .. a22 bottom-right)
// NOTE: mapping depends on your shift direction; this example assumes cur_s2 is leftmost
wire [11:0] a00 = r2_s2, a01 = r2_s1, a02 = r2_s0;
wire [11:0] a10 = r1_s2, a11 = r1_s1, a12 = r1_s0;
wire [11:0] a20 = cur_s2, a21 = cur_s1, a22 = cur_s0;

// delayed valid (pipeline depth = shifts + line-buffer latency)
// here shift regs add 2 cycles; adjust if your line buffer has other latency
logic win_valid_0, win_valid_1;
always @(posedge iCLK or negedge iRST) begin
  if (!iRST) {win_valid_0,win_valid_1} <= 0;
  else begin
    win_valid_0 <= mDVAL;
    win_valid_1 <= win_valid_0;
  end
end
assign window_valid = win_valid_1;

// example Sobel (signed accumulate; widen bits as needed)
wire signed [15:0] Gx = -$signed({1'b0,a00}) - 2*$signed({1'b0,a10}) - $signed({1'b0,a20})
                         + $signed({1'b0,a02}) + 2*$signed({1'b0,a12}) + $signed({1'b0,a22});
wire signed [15:0] Gy = -$signed({1'b0,a00}) - 2*$signed({1'b01,a01}) - $signed({1'b0,a02})
                         + $signed({1'b0,a20}) + 2*$signed({1'b0,a21}) + $signed({1'b0,a22});

// magnitude (simple abs sum or sqrt approximation)
assign mag = (Gx[15] ? -Gx : Gx) + (Gy[15] ? -Gy : Gy);


endmodule