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
    input [10:0] iY_Cont,
    input En
);

logic [11:0] mDATA_0, mDATA_1;
logic [11:0] mDATAd_0, mDATAd_1;
logic [13:0] gray,gray_scale;
logic mDVAL;

logic [11:0] gray_pixel;
logic [11:0] gDATA_0, gDATA_1;

logic [15:0] mag;
logic window_valid, valid_d1;

assign gray_pixel = gray_scale[13:2];

Line_Buffer1 u0(
    .clken(iDVAL),
    .clock(iCLK),
    .shiftin(iDATA),
    .taps0x(mDATA_1),
    .taps1x(mDATA_0)
);


assign oRed = mag[11:0]; // example: output edge magnitude as red; adjust bit slicing as needed
assign oGreen = mag[11:0];
assign oBlue = mag[11:0];
assign oDVAL = valid_d1; // output valid delayed by 1 cycle to align with output data

always @(posedge iCLK or negedge iRST) begin
    if (!iRST) begin
        gray_scale <= 0;
        mDATAd_0 <= 0;
        mDATAd_1 <= 0;
        mDVAL <= 0;
    end else begin
        mDATAd_0 <= mDATA_0;
        mDATAd_1 <= mDATA_1;
        mDVAL <= {iY_Cont[0] | iX_Cont[0]} ? 1'b0 : iDVAL;
        gray_scale <= (mDATA_0 + mDATA_1 + mDATAd_0 + mDATAd_1);
    end
end

logic [11:0] tap0, tap1, tap2; // taps from line-buffer

LineBuffer2 u1(
    .clken(mDVAL),
    .clock(iCLK),
    .shiftin(gray_pixel),
    .taps0x(tap2),          // current row pixel
    .taps1x(tap1),          // 1 previous row pixel (1 line below)
    .taps2x(tap0)           // 2 previous row pixel (2 lines below)
);

// assemble 3x3 neighborhood
logic [11:0] a00, a01, a02;
logic [11:0] a10, a11, a12;
logic [11:0] a20, a21, a22;
logic valid;

always @(posedge iCLK or negedge iRST) begin
  if (!iRST) begin
    {a00,a01,a02} <= 0;
    {a10,a11,a12} <= 0;
    {a20,a21,a22} <= 0;
    {valid,valid_d1} <= 0;
  end else if (mDVAL) begin
    valid <= 1;
    valid_d1 <= valid;

    a00 <= tap2;
    a01 <= a00;
    a02 <= a01;

    a10 <= tap1;
    a11 <= a10;
    a12 <= a11;

    a20 <= tap0;
    a21 <= a20;
    a22 <= a21;
  end
end

wire signed [15:0] Gy = -$signed({1'b0,a00}) - 2*$signed({1'b0,a10}) - $signed({1'b0,a20})
                         + $signed({1'b0,a02}) + 2*$signed({1'b0,a12}) + $signed({1'b0,a22});

wire signed [15:0] Gx = -$signed({1'b0,a00}) - 2*$signed({1'b0,a01}) - $signed({1'b0,a02})
                         + $signed({1'b0,a20}) + 2*$signed({1'b0,a21}) + $signed({1'b0,a22});


assign mag = (Gy[15] ? -Gy : Gy); 
endmodule