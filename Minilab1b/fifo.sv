module FIFO
#(
  parameter int DEPTH = 8,
  parameter int DATA_WIDTH = 8
)
(
    input  clk,
    input  rst_n,
    input  rden,
    input  wren,
    input  [DATA_WIDTH-1:0] i_data,
    output logic [DATA_WIDTH-1:0] o_data,
    output logic full,
    output logic empty
);

  logic [DATA_WIDTH-1:0] o_data_ff;
  logic full_ff;
  logic empty_ff;

  // localparam int ADDR_W = $clog2(DEPTH);

  // logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  // logic [ADDR_W-1:0] rd_ptr, wr_ptr;
  // logic [ADDR_W:0] cnt;

  // assign empty = (cnt == '0);
  // assign full  = (cnt == DEPTH);

  // always_ff @(posedge clk or negedge rst_n) begin
  //   if (!rst_n) begin
  //     rd_ptr <= '0;
  //     wr_ptr <= '0;
  //     cnt <= '0;
  //     o_data <= '0;
  //   end 
  //   else begin
  //     if (rden && !empty) begin
  //       o_data <= mem[rd_ptr];
  //       rd_ptr <= rd_ptr + 1'b1;
  //       cnt <= cnt - 1'b1;
  //     end
  //     else if (wren && !full) begin
  //       mem[wr_ptr] <= i_data;
  //       wr_ptr <= wr_ptr + 1'b1;
  //       cnt <= cnt + 1'b1;
  //     end
  //   end
  // end

 FIFO_IP iFIFO(.data(i_data), .clock(clk), .rdreq(rden), .wrreq(wren), .q(o_data_ff), .empty(empty_ff), .full(full_ff));

 always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        o_data <= '0;
        full <= 1'b0;
        empty <= 1'b1;
    end else begin
        o_data <= o_data_ff;
        full <= full_ff;
        empty <= empty_ff;
    end
 end

endmodule
