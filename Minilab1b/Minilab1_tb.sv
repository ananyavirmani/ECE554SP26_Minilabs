`timescale 1 ps / 1 ps

module Minilab1_tb();

localparam [23:0] c00 = 24'h0012CC;
localparam [23:0] c01 = 24'h00550C;
localparam [23:0] c02 = 24'h00974C;
localparam [23:0] c03 = 24'h00D98C;
localparam [23:0] c04 = 24'h011BCC;
localparam [23:0] c05 = 24'h015E0C;
localparam [23:0] c06 = 24'h01A04C;
localparam [23:0] c07 = 24'h01E28C;


logic clk;
logic rst_n;
logic start, Clr;

logic [6:0] HEX0;
logic [6:0] HEX1;
logic [6:0] HEX2;
logic [6:0] HEX3;
logic [6:0] HEX4;
logic [6:0] HEX5;

logic [9:0] SW;

integer i;

Minilab1 DUT(

	.CLOCK2_50(1'b0),
	.CLOCK3_50(1'b0),
	.CLOCK4_50(1'b0),
	.CLOCK_50(clk),

	.HEX0(HEX0),
	.HEX1(HEX1),
	.HEX2(HEX2),
	.HEX3(HEX3),
	.HEX4(HEX4),
	.HEX5(HEX5),
	
	.LEDR(),

	.KEY({1'b1, Clr, start, rst_n}),

	.SW(SW)
);

initial begin

    rst_n = 1'b0;
    clk = 0;
    start = 0;
    Clr = 1;

    @(negedge clk);

    rst_n = 1'b1;
    start = 1'b1;

    @(negedge clk);
    start = 1'b0;

    repeat (400) @(negedge clk);
    
    if(DUT.macout[0] !== c00) begin
        $display("TEST 0 FAILED: actual = %h, expected %h", DUT.macout[0], c00);
        $stop();
    end
    else begin
        $display("TEST 0 PASSED!");
    end

     if(DUT.macout[1] !== c01) begin
        $display("TEST 1 FAILED: actual = %h, expected %h", DUT.macout[1], c01);
        $stop();
    end
    else begin
        $display("TEST 1 PASSED!");
    end

     if(DUT.macout[2] !== c02) begin
        $display("TEST 2 FAILED: actual = %h, expected %h", DUT.macout[2], c02);
        $stop();
    end
    else begin
        $display("TEST 2 PASSED!");
    end

     if(DUT.macout[3] !== c03) begin
        $display("TEST 3 FAILED: actual = %h, expected %h", DUT.macout[3], c03);
        $stop();
    end
    else begin
        $display("TEST 3 PASSED!");
    end

     if(DUT.macout[4] !== c04) begin
        $display("TEST 4 FAILED: actual = %h, expected %h", DUT.macout[4], c04);
        $stop();
    end
    else begin
        $display("TEST 4 PASSED!");
    end

     if(DUT.macout[5] !== c05) begin
        $display("TEST 5 FAILED: actual = %h, expected %h", DUT.macout[5], c05);
        $stop();
    end
    else begin
        $display("TEST 5 PASSED!");
    end

     if(DUT.macout[6] !== c06) begin
        $display("TEST 6 FAILED: actual = %h, expected %h", DUT.macout[6], c06);
        $stop();
    end
    else begin
        $display("TEST 6 PASSED!");
    end

     if(DUT.macout[7] !== c07) begin
        $display("TEST 7 FAILED: actual = %h, expected %h", DUT.macout[7], c07);
        $stop();
    end
    else begin
        $display("TEST 7 PASSED!");
    end

    Clr = 1'b0;

    @(posedge clk);
    start = 1'b1;
    Clr = 1'b1;

    repeat (400) @(posedge clk);

    $display("YAHOO! ALL TESTS PASSED!!!!");
    $stop();

end

always #5 clk = ~clk;

endmodule