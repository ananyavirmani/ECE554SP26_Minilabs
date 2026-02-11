`timescale 1 ps / 1 ps

module Minilab1_tb();

localparam [6:0] c00 = 24'h0012CC;
localparam [6:0] c01 = 24'h00550C;
localparam [6:0] c02 = 24'h00974C;
localparam [6:0] c03 = 24'h00D98C;
localparam [6:0] c04 = 24'h011BCC;
localparam [6:0] c05 = 24'h015E0C;
localparam [6:0] c06 = 24'h01A04C;
localparam [6:0] c07 = 24'h01E28C;

localparam [6:0] c [0:7] = {c00, c01, c02, c03, c04, c05, c06, c07};

logic clk;
logic rst_n;

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

	.KEY({3'b111, rst_n}),

	.SW(SW)
);

initial begin

    rst_n = 1'b0;
    clk = 0;

    @(negedge clk);

    rst_n = 1'b1;

    repeat (400) @(negedge clk);
    // SW = 10'd1;
    // @(negedge clk);
    // $display("expected: %h, actual: %h", c00, {HEX5[3:0], HEX4[3:0], HEX3[3:0], HEX2[3:0], HEX1[3:0], HEX0[3:0]});

    // rst_n = 1'b0;
    // @(negedge clk);
    // rst_n = 1'b1;

    // repeat (400) @(negedge clk);
    // SW = 10'd1;
    // @(negedge clk);
    // $display("expected: %h, actual: %h", c00, {HEX5[3:0], HEX4[3:0], HEX3[3:0], HEX2[3:0], HEX1[3:0], HEX0[3:0]});

    for(i = 0; i < 8; i++)begin
        SW = 10'h001 << i;
        @(negedge clk);
        if(DUT.macout[i] != c[i]) begin
            $display("TEST %d FAILED: actual = %h, expected %h", i, DUT.macout[i], c[i]);
            $stop();
        end
    end   

    $display("YAHOO! ALL TESTS PASSED!!!!");
    $stop();

end

always #5 clk = ~clk;

endmodule