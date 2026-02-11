module MAC #
(
parameter DATA_WIDTH = 8
)
(
input clk,
input rst_n,
input En,
input Clr,
input [DATA_WIDTH-1:0] Ain,
input [DATA_WIDTH-1:0] Bin,
output logic [DATA_WIDTH*3-1:0] Cout
);

logic [DATA_WIDTH*3-1:0] product;
logic [DATA_WIDTH*3-1:0] internal_in;
logic [DATA_WIDTH*3-1:0] Cout_internal;

assign internal_in = Cout;

//assign product = Ain * Bin;

lpm_mult_ip iMULT(
	.clock(clk),
	.dataa(Ain),
	.datab(Bin),
	.result(product));
	
lpm_add_sub_ip iADD(
	.dataa(product),
	.datab(internal_in),
	.result(Cout_internal));

always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		Cout <= '0;
	else if(Clr)
		Cout <= '0;
	else if(En)
		Cout <= Cout_internal;
end

endmodule