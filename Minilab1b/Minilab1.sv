module Minilab1(

	//////////// CLOCK //////////
	input 		          		CLOCK2_50,
	input 		          		CLOCK3_50,
	input 		          		CLOCK4_50,
	input 		          		CLOCK_50,

	//////////// SEG7 //////////
	output	reg	     [6:0]		HEX0,
	output	reg	     [6:0]		HEX1,
	output	reg	     [6:0]		HEX2,
	output	reg	     [6:0]		HEX3,
	output	reg	     [6:0]		HEX4,
	output	reg	     [6:0]		HEX5,
	
	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// SW //////////
	input 		     [9:0]		SW
);

localparam DATA_WIDTH = 8;
localparam DEPTH = 8;

localparam MEM = 5'd0;
localparam MEM2 = 5'd1;
localparam FILL0 = 5'd2;
localparam FILL1 = 5'd3;
localparam FILL2 = 5'd4;
localparam FILL3 = 5'd5;
localparam FILL4 = 5'd6;
localparam FILL5 = 5'd7;
localparam FILL6 = 5'd8;
localparam FILL7 = 5'd9;
localparam EXEC0 = 5'd10;
localparam EXEC1 = 5'd11;
localparam EXEC2 = 5'd12;
localparam EXEC3 = 5'd13;
localparam EXEC4 = 5'd14;
localparam EXEC5 = 5'd15;
localparam EXEC6 = 5'd16;
localparam EXEC7 = 5'd17;
localparam EXEC8 = 5'd18;
localparam EXEC9 = 5'd19;
localparam EXEC10 = 5'd20;
localparam EXEC11 = 5'd21;
localparam EXEC12 = 5'd22;
localparam EXEC13 = 5'd23;
localparam EXEC14 = 5'd24;
localparam EXEC15 = 5'd25;
localparam EXEC16 = 5'd26;
localparam DONE1 = 5'd27;
localparam DONE2 = 5'd28;

parameter HEX_0 = 7'b1000000;		// zero
parameter HEX_1 = 7'b1111001;		// one
parameter HEX_2 = 7'b0100100;		// two
parameter HEX_3 = 7'b0110000;		// three
parameter HEX_4 = 7'b0011001;		// four
parameter HEX_5 = 7'b0010010;		// five
parameter HEX_6 = 7'b0000010;		// six
parameter HEX_7 = 7'b1111000;		// seven
parameter HEX_8 = 7'b0000000;		// eight
parameter HEX_9 = 7'b0011000;		// nine
parameter HEX_10 = 7'b0001000;	// ten
parameter HEX_11 = 7'b0000011;	// eleven
parameter HEX_12 = 7'b1000110;	// twelve
parameter HEX_13 = 7'b0100001;	// thirteen
parameter HEX_14 = 7'b0000110;	// fourteen
parameter HEX_15 = 7'b0001110;	// fifteen
parameter OFF   = 7'b1111111;		// all off

//=======================================================
//  REG/WIRE declarations
//=======================================================

reg [4:0] state, nxt_state;
reg [DATA_WIDTH-1:0] datain [0:8];
logic [DATA_WIDTH*3-1:0] result [0:7];

wire rst_n;
logic [8:0] rden, wren, full, empty;
logic [7:0] En;

logic [DATA_WIDTH-1:0] dataout [0:8];
logic [DATA_WIDTH-1:0] data_mac [0:7];
logic [DATA_WIDTH-1:0] data_mac_ff [0:7];
wire [DATA_WIDTH*3-1:0] macout [0:7];

logic [3:0] cntr;
logic inc_cntr, inc_address;
logic read;
logic [31:0] address;
logic [63:0] readdata;
logic readdatavalid;
logic waitrequest;

//=======================================================
//  Module instantiation
//=======================================================

genvar i, k;

generate
  for (i=0; i<9; i=i+1) begin : fifo_gen
    FIFO
    #(
    .DEPTH(DEPTH),
    .DATA_WIDTH(DATA_WIDTH)
    ) input_fifo
    (
    .clk(CLOCK_50),
    .rst_n(rst_n),
    .rden(rden[i]),
    .wren(wren[i]),
    .i_data(datain[i]),
    .o_data(dataout[i]),
    .full(full[i]),
    .empty(empty[i])
    );
  end
endgenerate

generate
  for (k=0; k<8; k=k+1) begin : mac_gen
MAC
#(
.DATA_WIDTH(DATA_WIDTH)
) mac
(
.clk(CLOCK_50),
.rst_n(rst_n),
.En(En[k]),
.Clr(1'b0),
.Ain(dataout[k]),
.Bin(data_mac[k]),
.Cout(macout[k])
);
  end
endgenerate

mem_wrapper iMEM(
    .clk(CLOCK_50),
    .reset_n(rst_n),
    .address(address),      
    .read(read),                
    .readdata(readdata),    
    .readdatavalid(readdatavalid),       
	 .waitrequest(waitrequest)
);

//=======================================================
//  Structural coding
//=======================================================

assign rst_n = KEY[0];

integer j, l;

always @(posedge CLOCK_50 or negedge rst_n) begin
	if(!rst_n) begin
		state <= MEM;
	end
	else
		state <= nxt_state;
end

always_ff @(posedge CLOCK_50 or negedge rst_n) begin
	if (!rst_n)
		cntr <= 3'b0;
	else if (inc_cntr)
		cntr <= cntr + 1;
end

always_ff @(posedge CLOCK_50 or negedge rst_n) begin
	if (!rst_n)
		address <= 32'b0;
	else if (inc_address)
		address <= address + 1'b1;
end

logic shift_en;
assign shift_en = (state >= EXEC0 && state <= EXEC8);

always_ff @(posedge CLOCK_50 or negedge rst_n) begin
  if (!rst_n) begin
    for (int i = 0; i < 8; i = i + 1)
      data_mac_ff[i] <= '0;
  end
  else begin
    for (int i = 7; i >= 0; i = i - 1)
      data_mac_ff[i] <= data_mac[i];
  end
end

integer z;

always_comb begin

	nxt_state = state;
	read = 1'b0;
	inc_cntr = 1'b0;
	inc_address = 1'b0;
	wren = 9'b0;
	rden = 9'b0;

	for (z = 0; z < 8; z = z + 1) begin
		En[z] = '0;
	end

	for (z = 0; z < 8; z = z + 1) begin
		result[z] = '0;
	end

	for (z = 0; z < 8; z = z + 1) begin
		data_mac[z] = '0;
	end

	for (z = 0; z < 9; z = z + 1) begin
		datain[z] = '0;
	end

	case(state)
	

		MEM: begin
			read = 1'b1;
			if(readdatavalid) begin
				nxt_state = MEM2;
			end
		end

		MEM2: begin
			if(readdatavalid) begin
				nxt_state = FILL0;
			end
		end

		FILL0 : begin
			nxt_state = FILL1;
			datain[cntr] = readdata[7:0];
			wren[cntr] = 1'b1;
		end

		FILL1 : begin
			nxt_state = FILL2;
			datain[cntr] = readdata[15:8];
			wren[cntr] = 1'b1;
		end

		FILL2 : begin
			nxt_state = FILL3;
			datain[cntr] = readdata[23:16];
			wren[cntr] = 1'b1;
		end

		FILL3 : begin
			nxt_state = FILL4;
			datain[cntr] = readdata[31:24];
			wren[cntr] = 1'b1;
		end

		FILL4 : begin
			nxt_state = FILL5;
			datain[cntr] = readdata[39:32];
			wren[cntr] = 1'b1;
		end

		FILL5 : begin
			nxt_state = FILL6;
			datain[cntr] = readdata[47:40];
			wren[cntr] = 1'b1;
		end

		FILL6 : begin
			nxt_state = FILL7;
			datain[cntr] = readdata[55:48];
			wren[cntr] = 1'b1;
		end

		FILL7 : begin
			datain[cntr] = readdata[63:56];
			wren[cntr] = 1'b1;
			inc_cntr = 1'b1;
			inc_address = 1'b1;

			if(cntr != 4'd8)
				nxt_state = MEM;
			else
				nxt_state = EXEC0;
		end

		EXEC0 : begin
			rden[0] = 1'b1;
			rden[8] = 1'b1;
			En[0] = 1'b1;
			data_mac[0] = dataout[8];
			nxt_state = EXEC1;
		end

		EXEC1 : begin
			rden[0] = 1'b1;
			rden[1] = 1'b1;
			rden[8] = 1'b1;
			En[0] = 1'b1;
			En[1] = 1'b1;
			data_mac[1] = data_mac_ff[0];
			data_mac[0] = dataout[8];
			nxt_state = EXEC2;
		end

		EXEC2 : begin
			rden[0] = 1'b1;
			rden[1] = 1'b1;
			rden[2] = 1'b1;
			rden[8] = 1'b1;
			En[0] = 1'b1;
			En[1] = 1'b1;
			En[2] = 1'b1;
			data_mac[2] = data_mac_ff[1];
			data_mac[1] = data_mac_ff[0];
			data_mac[0] = dataout[8];
			nxt_state = EXEC3;
		end

		EXEC3 : begin
			rden[0] = 1'b1;
			rden[1] = 1'b1;
			rden[2] = 1'b1;
			rden[3] = 1'b1;
			rden[8] = 1'b1;
			En[0] = 1'b1;
			En[1] = 1'b1;
			En[2] = 1'b1;
			En[3] = 1'b1;
			data_mac[3] = data_mac_ff[2];
			data_mac[2] = data_mac_ff[1];
			data_mac[1] = data_mac_ff[0];
			data_mac[0] = dataout[8];
			nxt_state = EXEC4;
		end

		EXEC4 : begin
			rden[0] = 1'b1;
			rden[1] = 1'b1;
			rden[2] = 1'b1;
			rden[3] = 1'b1;
			rden[4] = 1'b1;
			rden[8] = 1'b1;
			En[0] = 1'b1;
			En[1] = 1'b1;
			En[2] = 1'b1;
			En[3] = 1'b1;
			En[4] = 1'b1;
			data_mac[4] = data_mac_ff[3];
			data_mac[3] = data_mac_ff[2];
			data_mac[2] = data_mac_ff[1];
			data_mac[1] = data_mac_ff[0];
			data_mac[0] = dataout[8];
			nxt_state = EXEC5;
		end

		EXEC5 : begin
			rden[0] = 1'b1;
			rden[1] = 1'b1;
			rden[2] = 1'b1;
			rden[3] = 1'b1;
			rden[4] = 1'b1;
			rden[5] = 1'b1;
			rden[8] = 1'b1;
			En[0] = 1'b1;
			En[1] = 1'b1;
			En[2] = 1'b1;
			En[3] = 1'b1;
			En[4] = 1'b1;
			En[5] = 1'b1;
			data_mac[5] = data_mac_ff[4];
			data_mac[4] = data_mac_ff[3];
			data_mac[3] = data_mac_ff[2];
			data_mac[2] = data_mac_ff[1];
			data_mac[1] = data_mac_ff[0];
			data_mac[0] = dataout[8];
			nxt_state = EXEC6;
		end

		EXEC6 : begin
			rden[0] = 1'b1;
			rden[1] = 1'b1;
			rden[2] = 1'b1;
			rden[3] = 1'b1;
			rden[4] = 1'b1;
			rden[5] = 1'b1;
			rden[6] = 1'b1;
			rden[8] = 1'b1;
			En[0] = 1'b1;
			En[1] = 1'b1;
			En[2] = 1'b1;
			En[3] = 1'b1;
			En[4] = 1'b1;
			En[5] = 1'b1;
			En[6] = 1'b1;
			data_mac[6] = data_mac_ff[5];
			data_mac[5] = data_mac_ff[4];
			data_mac[4] = data_mac_ff[3];
			data_mac[3] = data_mac_ff[2];
			data_mac[2] = data_mac_ff[1];
			data_mac[1] = data_mac_ff[0];
			data_mac[0] = dataout[8];
			nxt_state = EXEC7;
		end

		EXEC7 : begin
			rden[0] = 1'b1;
			rden[1] = 1'b1;
			rden[2] = 1'b1;
			rden[3] = 1'b1;
			rden[4] = 1'b1;
			rden[5] = 1'b1;
			rden[6] = 1'b1;
			rden[7] = 1'b1;
			rden[8] = 1'b1;
			En[0] = 1'b1;
			En[1] = 1'b1;
			En[2] = 1'b1;
			En[3] = 1'b1;
			En[4] = 1'b1;
			En[5] = 1'b1;
			En[6] = 1'b1;
			En[7] = 1'b1;
			data_mac[7] = data_mac_ff[6];
			data_mac[6] = data_mac_ff[5];
			data_mac[5] = data_mac_ff[4];
			data_mac[4] = data_mac_ff[3];
			data_mac[3] = data_mac_ff[2];
			data_mac[2] = data_mac_ff[1];
			data_mac[1] = data_mac_ff[0];
			data_mac[0] = dataout[8];
			nxt_state = EXEC8;
		end

		EXEC8 : begin
			rden[0] = 1'b1;
			rden[1] = 1'b1;
			rden[2] = 1'b1;
			rden[3] = 1'b1;
			rden[4] = 1'b1;
			rden[5] = 1'b1;
			rden[6] = 1'b1;
			rden[7] = 1'b1;
			rden[8] = 1'b1;
			En[0] = 1'b1;
			En[1] = 1'b1;
			En[2] = 1'b1;
			En[3] = 1'b1;
			En[4] = 1'b1;
			En[5] = 1'b1;
			En[6] = 1'b1;
			En[7] = 1'b1;
			data_mac[7] = data_mac_ff[6];
			data_mac[6] = data_mac_ff[5];
			data_mac[5] = data_mac_ff[4];
			data_mac[4] = data_mac_ff[3];
			data_mac[3] = data_mac_ff[2];
			data_mac[2] = data_mac_ff[1];
			data_mac[1] = data_mac_ff[0];
			data_mac[0] = dataout[8];
			nxt_state = EXEC9;
		end	

		
		EXEC9 : begin
			rden[2] = 1'b1;
			rden[3] = 1'b1;
			rden[4] = 1'b1;
			rden[5] = 1'b1;
			rden[6] = 1'b1;
			rden[7] = 1'b1;
			rden[8] = 1'b1;
			En[0] = 1'b1;
			En[1] = 1'b1;
			En[2] = 1'b1;
			En[3] = 1'b1;
			En[4] = 1'b1;
			En[5] = 1'b1;
			En[6] = 1'b1;
			En[7] = 1'b1;
			data_mac[7] = data_mac_ff[6];
			data_mac[6] = data_mac_ff[5];
			data_mac[5] = data_mac_ff[4];
			data_mac[4] = data_mac_ff[3];
			data_mac[3] = data_mac_ff[2];
			data_mac[2] = data_mac_ff[1];
			data_mac[1] = data_mac_ff[0];
			data_mac[0] = dataout[8];
			nxt_state = EXEC10;
		end

		
		EXEC10 : begin
			rden[3] = 1'b1;
			rden[4] = 1'b1;
			rden[5] = 1'b1;
			rden[6] = 1'b1;
			rden[7] = 1'b1;
			rden[8] = 1'b1;
			En[0] = 1'b1;
			En[1] = 1'b1;
			En[2] = 1'b1;
			En[3] = 1'b1;
			En[4] = 1'b1;
			En[5] = 1'b1;
			En[6] = 1'b1;
			En[7] = 1'b1;
			data_mac[7] = data_mac_ff[6];
			data_mac[6] = data_mac_ff[5];
			data_mac[5] = data_mac_ff[4];
			data_mac[4] = data_mac_ff[3];
			data_mac[3] = data_mac_ff[2];
			data_mac[2] = data_mac_ff[1];
			data_mac[1] = data_mac_ff[0];
			nxt_state = EXEC11;
		end

		
		EXEC11 : begin
			rden[4] = 1'b1;
			rden[5] = 1'b1;
			rden[6] = 1'b1;
			rden[7] = 1'b1;
			rden[8] = 1'b1;
			En[0] = 1'b1;
			En[1] = 1'b1;
			En[2] = 1'b1;
			En[3] = 1'b1;
			En[4] = 1'b1;
			En[5] = 1'b1;
			En[6] = 1'b1;
			En[7] = 1'b1;
			data_mac[7] = data_mac_ff[6];
			data_mac[6] = data_mac_ff[5];
			data_mac[5] = data_mac_ff[4];
			data_mac[4] = data_mac_ff[3];
			data_mac[3] = data_mac_ff[2];
			data_mac[2] = data_mac_ff[1];
			nxt_state = EXEC12;
		end

		
		EXEC12 : begin
			rden[5] = 1'b1;
			rden[6] = 1'b1;
			rden[7] = 1'b1;
			rden[8] = 1'b1;
			En[1] = 1'b1;
			En[2] = 1'b1;
			En[3] = 1'b1;
			En[4] = 1'b1;
			En[5] = 1'b1;
			En[6] = 1'b1;
			En[7] = 1'b1;
			data_mac[7] = data_mac_ff[6];
			data_mac[6] = data_mac_ff[5];
			data_mac[5] = data_mac_ff[4];
			data_mac[4] = data_mac_ff[3];
			data_mac[3] = data_mac_ff[2];
			nxt_state = EXEC13;
		end

		
		EXEC13 : begin
			rden[6] = 1'b1;
			rden[7] = 1'b1;
			rden[8] = 1'b1;
			En[2] = 1'b1;
			En[3] = 1'b1;
			En[4] = 1'b1;
			En[5] = 1'b1;
			En[6] = 1'b1;
			En[7] = 1'b1;
			data_mac[7] = data_mac_ff[6];
			data_mac[6] = data_mac_ff[5];
			data_mac[5] = data_mac_ff[4];
			data_mac[4] = data_mac_ff[3];
			nxt_state = EXEC14;
		end

		
		EXEC14 : begin
			rden[7] = 1'b1;
			rden[8] = 1'b1;
			En[3] = 1'b1;
			En[4] = 1'b1;
			En[5] = 1'b1;
			En[6] = 1'b1;
			En[7] = 1'b1;
			data_mac[7] = data_mac_ff[6];
			data_mac[6] = data_mac_ff[5];
			data_mac[5] = data_mac_ff[4];
			nxt_state = EXEC15;
		end

		EXEC15:
		begin
			data_mac[7] = data_mac_ff[6];
			data_mac[6] = data_mac_ff[5];
			En[4] = 1'b1;
			En[5] = 1'b1;
			En[6] = 1'b1;
			En[7] = 1'b1;
			// if(empty[7] & empty[8])
				nxt_state = EXEC16;
		end

		EXEC16:
		begin
			data_mac[7] = data_mac_ff[6];
			data_mac[6] = data_mac_ff[5];
			En[5] = 1'b1;
			En[6] = 1'b1;
			En[7] = 1'b1;
			// if(empty[7] & empty[8])
				nxt_state = DONE1;
		end

		DONE1 : begin
			data_mac[7] = data_mac_ff[6];
			En[6] = 1'b1;
			En[7] = 1'b1;
        	if (empty[7] & empty[8])
				nxt_state = DONE2;
		end

		DONE2 : begin
			En[7] = 1'b1;
        	result = macout;
		end

	endcase
end


integer n;

always @(*) begin
		if (state == DONE2 & SW[0]) begin
			case(macout[0][3:0])
			4'd0: HEX0 = HEX_0;
			4'd1: HEX0 = HEX_1;
			4'd2: HEX0 = HEX_2;
			4'd3: HEX0 = HEX_3;
			4'd4: HEX0 = HEX_4;
			4'd5: HEX0 = HEX_5;
			4'd6: HEX0 = HEX_6;
			4'd7: HEX0 = HEX_7;
			4'd8: HEX0 = HEX_8;
			4'd9: HEX0 = HEX_9;
			4'd10: HEX0 = HEX_10;
			4'd11: HEX0 = HEX_11;
			4'd12: HEX0 = HEX_12;
			4'd13: HEX0 = HEX_13;
			4'd14: HEX0 = HEX_14;
			4'd15: HEX0 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[1]) begin
			case(macout[1][3:0])
			4'd0: HEX0 = HEX_0;
			4'd1: HEX0 = HEX_1;
			4'd2: HEX0 = HEX_2;
			4'd3: HEX0 = HEX_3;
			4'd4: HEX0 = HEX_4;
			4'd5: HEX0 = HEX_5;
			4'd6: HEX0 = HEX_6;
			4'd7: HEX0 = HEX_7;
			4'd8: HEX0 = HEX_8;
			4'd9: HEX0 = HEX_9;
			4'd10: HEX0 = HEX_10;
			4'd11: HEX0 = HEX_11;
			4'd12: HEX0 = HEX_12;
			4'd13: HEX0 = HEX_13;
			4'd14: HEX0 = HEX_14;
			4'd15: HEX0 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[2]) begin
			case(macout[2][3:0])
			4'd0: HEX0 = HEX_0;
			4'd1: HEX0 = HEX_1;
			4'd2: HEX0 = HEX_2;
			4'd3: HEX0 = HEX_3;
			4'd4: HEX0 = HEX_4;
			4'd5: HEX0 = HEX_5;
			4'd6: HEX0 = HEX_6;
			4'd7: HEX0 = HEX_7;
			4'd8: HEX0 = HEX_8;
			4'd9: HEX0 = HEX_9;
			4'd10: HEX0 = HEX_10;
			4'd11: HEX0 = HEX_11;
			4'd12: HEX0 = HEX_12;
			4'd13: HEX0 = HEX_13;
			4'd14: HEX0 = HEX_14;
			4'd15: HEX0 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[3]) begin
			case(macout[3][3:0])
			4'd0: HEX0 = HEX_0;
			4'd1: HEX0 = HEX_1;
			4'd2: HEX0 = HEX_2;
			4'd3: HEX0 = HEX_3;
			4'd4: HEX0 = HEX_4;
			4'd5: HEX0 = HEX_5;
			4'd6: HEX0 = HEX_6;
			4'd7: HEX0 = HEX_7;
			4'd8: HEX0 = HEX_8;
			4'd9: HEX0 = HEX_9;
			4'd10: HEX0 = HEX_10;
			4'd11: HEX0 = HEX_11;
			4'd12: HEX0 = HEX_12;
			4'd13: HEX0 = HEX_13;
			4'd14: HEX0 = HEX_14;
			4'd15: HEX0 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[4]) begin
			case(macout[4][3:0])
			4'd0: HEX0 = HEX_0;
			4'd1: HEX0 = HEX_1;
			4'd2: HEX0 = HEX_2;
			4'd3: HEX0 = HEX_3;
			4'd4: HEX0 = HEX_4;
			4'd5: HEX0 = HEX_5;
			4'd6: HEX0 = HEX_6;
			4'd7: HEX0 = HEX_7;
			4'd8: HEX0 = HEX_8;
			4'd9: HEX0 = HEX_9;
			4'd10: HEX0 = HEX_10;
			4'd11: HEX0 = HEX_11;
			4'd12: HEX0 = HEX_12;
			4'd13: HEX0 = HEX_13;
			4'd14: HEX0 = HEX_14;
			4'd15: HEX0 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[5]) begin
			case(macout[5][3:0])
			4'd0: HEX0 = HEX_0;
			4'd1: HEX0 = HEX_1;
			4'd2: HEX0 = HEX_2;
			4'd3: HEX0 = HEX_3;
			4'd4: HEX0 = HEX_4;
			4'd5: HEX0 = HEX_5;
			4'd6: HEX0 = HEX_6;
			4'd7: HEX0 = HEX_7;
			4'd8: HEX0 = HEX_8;
			4'd9: HEX0 = HEX_9;
			4'd10: HEX0 = HEX_10;
			4'd11: HEX0 = HEX_11;
			4'd12: HEX0 = HEX_12;
			4'd13: HEX0 = HEX_13;
			4'd14: HEX0 = HEX_14;
			4'd15: HEX0 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[6]) begin
			case(macout[6][3:0])
			4'd0: HEX0 = HEX_0;
			4'd1: HEX0 = HEX_1;
			4'd2: HEX0 = HEX_2;
			4'd3: HEX0 = HEX_3;
			4'd4: HEX0 = HEX_4;
			4'd5: HEX0 = HEX_5;
			4'd6: HEX0 = HEX_6;
			4'd7: HEX0 = HEX_7;
			4'd8: HEX0 = HEX_8;
			4'd9: HEX0 = HEX_9;
			4'd10: HEX0 = HEX_10;
			4'd11: HEX0 = HEX_11;
			4'd12: HEX0 = HEX_12;
			4'd13: HEX0 = HEX_13;
			4'd14: HEX0 = HEX_14;
			4'd15: HEX0 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[7]) begin
			case(macout[7][3:0])
			4'd0: HEX0 = HEX_0;
			4'd1: HEX0 = HEX_1;
			4'd2: HEX0 = HEX_2;
			4'd3: HEX0 = HEX_3;
			4'd4: HEX0 = HEX_4;
			4'd5: HEX0 = HEX_5;
			4'd6: HEX0 = HEX_6;
			4'd7: HEX0 = HEX_7;
			4'd8: HEX0 = HEX_8;
			4'd9: HEX0 = HEX_9;
			4'd10: HEX0 = HEX_10;
			4'd11: HEX0 = HEX_11;
			4'd12: HEX0 = HEX_12;
			4'd13: HEX0 = HEX_13;
			4'd14: HEX0 = HEX_14;
			4'd15: HEX0 = HEX_15;
			endcase
		end
		else begin
			HEX0 = OFF;
		end
end

always @(*) begin
		if (state == DONE2 & SW[0]) begin
			case(macout[0][7:4])
			4'd0: HEX1 = HEX_0;
			4'd1: HEX1 = HEX_1;
			4'd2: HEX1 = HEX_2;
			4'd3: HEX1 = HEX_3;
			4'd4: HEX1 = HEX_4;
			4'd5: HEX1 = HEX_5;
			4'd6: HEX1 = HEX_6;
			4'd7: HEX1 = HEX_7;
			4'd8: HEX1 = HEX_8;
			4'd9: HEX1 = HEX_9;
			4'd10: HEX1 = HEX_10;
			4'd11: HEX1 = HEX_11;
			4'd12: HEX1 = HEX_12;
			4'd13: HEX1 = HEX_13;
			4'd14: HEX1 = HEX_14;
			4'd15: HEX1 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[1]) begin
			case(macout[1][7:4])
			4'd0: HEX1 = HEX_0;
			4'd1: HEX1 = HEX_1;
			4'd2: HEX1 = HEX_2;
			4'd3: HEX1 = HEX_3;
			4'd4: HEX1 = HEX_4;
			4'd5: HEX1 = HEX_5;
			4'd6: HEX1 = HEX_6;
			4'd7: HEX1 = HEX_7;
			4'd8: HEX1 = HEX_8;
			4'd9: HEX1 = HEX_9;
			4'd10: HEX1 = HEX_10;
			4'd11: HEX1 = HEX_11;
			4'd12: HEX1 = HEX_12;
			4'd13: HEX1 = HEX_13;
			4'd14: HEX1 = HEX_14;
			4'd15: HEX1 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[2]) begin
			case(macout[2][7:4])
			4'd0: HEX1 = HEX_0;
			4'd1: HEX1 = HEX_1;
			4'd2: HEX1 = HEX_2;
			4'd3: HEX1 = HEX_3;
			4'd4: HEX1 = HEX_4;
			4'd5: HEX1 = HEX_5;
			4'd6: HEX1 = HEX_6;
			4'd7: HEX1 = HEX_7;
			4'd8: HEX1 = HEX_8;
			4'd9: HEX1 = HEX_9;
			4'd10: HEX1 = HEX_10;
			4'd11: HEX1 = HEX_11;
			4'd12: HEX1 = HEX_12;
			4'd13: HEX1 = HEX_13;
			4'd14: HEX1 = HEX_14;
			4'd15: HEX1 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[3]) begin
			case(macout[3][7:4])
			4'd0: HEX1 = HEX_0;
			4'd1: HEX1 = HEX_1;
			4'd2: HEX1 = HEX_2;
			4'd3: HEX1 = HEX_3;
			4'd4: HEX1 = HEX_4;
			4'd5: HEX1 = HEX_5;
			4'd6: HEX1 = HEX_6;
			4'd7: HEX1 = HEX_7;
			4'd8: HEX1 = HEX_8;
			4'd9: HEX1 = HEX_9;
			4'd10: HEX1 = HEX_10;
			4'd11: HEX1 = HEX_11;
			4'd12: HEX1 = HEX_12;
			4'd13: HEX1 = HEX_13;
			4'd14: HEX1 = HEX_14;
			4'd15: HEX1 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[4]) begin
			case(macout[4][7:4])
			4'd0: HEX1 = HEX_0;
			4'd1: HEX1 = HEX_1;
			4'd2: HEX1 = HEX_2;
			4'd3: HEX1 = HEX_3;
			4'd4: HEX1 = HEX_4;
			4'd5: HEX1 = HEX_5;
			4'd6: HEX1 = HEX_6;
			4'd7: HEX1 = HEX_7;
			4'd8: HEX1 = HEX_8;
			4'd9: HEX1 = HEX_9;
			4'd10: HEX1 = HEX_10;
			4'd11: HEX1 = HEX_11;
			4'd12: HEX1 = HEX_12;
			4'd13: HEX1 = HEX_13;
			4'd14: HEX1 = HEX_14;
			4'd15: HEX1 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[5]) begin
			case(macout[5][7:4])
			4'd0: HEX1 = HEX_0;
			4'd1: HEX1 = HEX_1;
			4'd2: HEX1 = HEX_2;
			4'd3: HEX1 = HEX_3;
			4'd4: HEX1 = HEX_4;
			4'd5: HEX1 = HEX_5;
			4'd6: HEX1 = HEX_6;
			4'd7: HEX1 = HEX_7;
			4'd8: HEX1 = HEX_8;
			4'd9: HEX1 = HEX_9;
			4'd10: HEX1 = HEX_10;
			4'd11: HEX1 = HEX_11;
			4'd12: HEX1 = HEX_12;
			4'd13: HEX1 = HEX_13;
			4'd14: HEX1 = HEX_14;
			4'd15: HEX1 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[6]) begin
			case(macout[6][7:4])
			4'd0: HEX1 = HEX_0;
			4'd1: HEX1 = HEX_1;
			4'd2: HEX1 = HEX_2;
			4'd3: HEX1 = HEX_3;
			4'd4: HEX1 = HEX_4;
			4'd5: HEX1 = HEX_5;
			4'd6: HEX1 = HEX_6;
			4'd7: HEX1 = HEX_7;
			4'd8: HEX1 = HEX_8;
			4'd9: HEX1 = HEX_9;
			4'd10: HEX1 = HEX_10;
			4'd11: HEX1 = HEX_11;
			4'd12: HEX1 = HEX_12;
			4'd13: HEX1 = HEX_13;
			4'd14: HEX1 = HEX_14;
			4'd15: HEX1 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[7]) begin
			case(macout[7][7:4])
			4'd0: HEX1 = HEX_0;
			4'd1: HEX1 = HEX_1;
			4'd2: HEX1 = HEX_2;
			4'd3: HEX1 = HEX_3;
			4'd4: HEX1 = HEX_4;
			4'd5: HEX1 = HEX_5;
			4'd6: HEX1 = HEX_6;
			4'd7: HEX1 = HEX_7;
			4'd8: HEX1 = HEX_8;
			4'd9: HEX1 = HEX_9;
			4'd10: HEX1 = HEX_10;
			4'd11: HEX1 = HEX_11;
			4'd12: HEX1 = HEX_12;
			4'd13: HEX1 = HEX_13;
			4'd14: HEX1 = HEX_14;
			4'd15: HEX1 = HEX_15;
			endcase
		end
		else begin
			HEX1 = OFF;
		end
end

always @(*) begin
		if (state == DONE2 & SW[0]) begin
			case(macout[0][11:8])
			4'd0: HEX2 = HEX_0;
			4'd1: HEX2 = HEX_1;
			4'd2: HEX2 = HEX_2;
			4'd3: HEX2 = HEX_3;
			4'd4: HEX2 = HEX_4;
			4'd5: HEX2 = HEX_5;
			4'd6: HEX2 = HEX_6;
			4'd7: HEX2 = HEX_7;
			4'd8: HEX2 = HEX_8;
			4'd9: HEX2 = HEX_9;
			4'd10: HEX2 = HEX_10;
			4'd11: HEX2 = HEX_11;
			4'd12: HEX2 = HEX_12;
			4'd13: HEX2 = HEX_13;
			4'd14: HEX2 = HEX_14;
			4'd15: HEX2 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[1]) begin
			case(macout[1][11:8])
			4'd0: HEX2 = HEX_0;
			4'd1: HEX2 = HEX_1;
			4'd2: HEX2 = HEX_2;
			4'd3: HEX2 = HEX_3;
			4'd4: HEX2 = HEX_4;
			4'd5: HEX2 = HEX_5;
			4'd6: HEX2 = HEX_6;
			4'd7: HEX2 = HEX_7;
			4'd8: HEX2 = HEX_8;
			4'd9: HEX2 = HEX_9;
			4'd10: HEX2 = HEX_10;
			4'd11: HEX2 = HEX_11;
			4'd12: HEX2 = HEX_12;
			4'd13: HEX2 = HEX_13;
			4'd14: HEX2 = HEX_14;
			4'd15: HEX2 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[2]) begin
			case(macout[2][11:8])
			4'd0: HEX2 = HEX_0;
			4'd1: HEX2 = HEX_1;
			4'd2: HEX2 = HEX_2;
			4'd3: HEX2 = HEX_3;
			4'd4: HEX2 = HEX_4;
			4'd5: HEX2 = HEX_5;
			4'd6: HEX2 = HEX_6;
			4'd7: HEX2 = HEX_7;
			4'd8: HEX2 = HEX_8;
			4'd9: HEX2 = HEX_9;
			4'd10: HEX2 = HEX_10;
			4'd11: HEX2 = HEX_11;
			4'd12: HEX2 = HEX_12;
			4'd13: HEX2 = HEX_13;
			4'd14: HEX2 = HEX_14;
			4'd15: HEX2 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[3]) begin
			case(macout[3][11:8])
			4'd0: HEX2 = HEX_0;
			4'd1: HEX2 = HEX_1;
			4'd2: HEX2 = HEX_2;
			4'd3: HEX2 = HEX_3;
			4'd4: HEX2 = HEX_4;
			4'd5: HEX2 = HEX_5;
			4'd6: HEX2 = HEX_6;
			4'd7: HEX2 = HEX_7;
			4'd8: HEX2 = HEX_8;
			4'd9: HEX2 = HEX_9;
			4'd10: HEX2 = HEX_10;
			4'd11: HEX2 = HEX_11;
			4'd12: HEX2 = HEX_12;
			4'd13: HEX2 = HEX_13;
			4'd14: HEX2 = HEX_14;
			4'd15: HEX2 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[4]) begin
			case(macout[4][11:8])
			4'd0: HEX2 = HEX_0;
			4'd1: HEX2 = HEX_1;
			4'd2: HEX2 = HEX_2;
			4'd3: HEX2 = HEX_3;
			4'd4: HEX2 = HEX_4;
			4'd5: HEX2 = HEX_5;
			4'd6: HEX2 = HEX_6;
			4'd7: HEX2 = HEX_7;
			4'd8: HEX2 = HEX_8;
			4'd9: HEX2 = HEX_9;
			4'd10: HEX2 = HEX_10;
			4'd11: HEX2 = HEX_11;
			4'd12: HEX2 = HEX_12;
			4'd13: HEX2 = HEX_13;
			4'd14: HEX2 = HEX_14;
			4'd15: HEX2 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[5]) begin
			case(macout[5][11:8])
			4'd0: HEX2 = HEX_0;
			4'd1: HEX2 = HEX_1;
			4'd2: HEX2 = HEX_2;
			4'd3: HEX2 = HEX_3;
			4'd4: HEX2 = HEX_4;
			4'd5: HEX2 = HEX_5;
			4'd6: HEX2 = HEX_6;
			4'd7: HEX2 = HEX_7;
			4'd8: HEX2 = HEX_8;
			4'd9: HEX2 = HEX_9;
			4'd10: HEX2 = HEX_10;
			4'd11: HEX2 = HEX_11;
			4'd12: HEX2 = HEX_12;
			4'd13: HEX2 = HEX_13;
			4'd14: HEX2 = HEX_14;
			4'd15: HEX2 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[6]) begin
			case(macout[6][11:8])
			4'd0: HEX2 = HEX_0;
			4'd1: HEX2 = HEX_1;
			4'd2: HEX2 = HEX_2;
			4'd3: HEX2 = HEX_3;
			4'd4: HEX2 = HEX_4;
			4'd5: HEX2 = HEX_5;
			4'd6: HEX2 = HEX_6;
			4'd7: HEX2 = HEX_7;
			4'd8: HEX2 = HEX_8;
			4'd9: HEX2 = HEX_9;
			4'd10: HEX2 = HEX_10;
			4'd11: HEX2 = HEX_11;
			4'd12: HEX2 = HEX_12;
			4'd13: HEX2 = HEX_13;
			4'd14: HEX2 = HEX_14;
			4'd15: HEX2 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[7]) begin
			case(macout[7][11:8])
			4'd0: HEX2 = HEX_0;
			4'd1: HEX2 = HEX_1;
			4'd2: HEX2 = HEX_2;
			4'd3: HEX2 = HEX_3;
			4'd4: HEX2 = HEX_4;
			4'd5: HEX2 = HEX_5;
			4'd6: HEX2 = HEX_6;
			4'd7: HEX2 = HEX_7;
			4'd8: HEX2 = HEX_8;
			4'd9: HEX2 = HEX_9;
			4'd10: HEX2 = HEX_10;
			4'd11: HEX2 = HEX_11;
			4'd12: HEX2 = HEX_12;
			4'd13: HEX2 = HEX_13;
			4'd14: HEX2 = HEX_14;
			4'd15: HEX2 = HEX_15;
			endcase
		end
		else begin
			HEX2 = OFF;
		end
end

always @(*) begin
		if (state == DONE2 & SW[0]) begin
			case(macout[0][15:12])
			4'd0: HEX3 = HEX_0;
			4'd1: HEX3 = HEX_1;
			4'd2: HEX3 = HEX_2;
			4'd3: HEX3 = HEX_3;
			4'd4: HEX3 = HEX_4;
			4'd5: HEX3 = HEX_5;
			4'd6: HEX3 = HEX_6;
			4'd7: HEX3 = HEX_7;
			4'd8: HEX3 = HEX_8;
			4'd9: HEX3 = HEX_9;
			4'd10: HEX3 = HEX_10;
			4'd11: HEX3 = HEX_11;
			4'd12: HEX3 = HEX_12;
			4'd13: HEX3 = HEX_13;
			4'd14: HEX3 = HEX_14;
			4'd15: HEX3 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[1]) begin
			case(macout[1][15:12])
			4'd0: HEX3 = HEX_0;
			4'd1: HEX3 = HEX_1;
			4'd2: HEX3 = HEX_2;
			4'd3: HEX3 = HEX_3;
			4'd4: HEX3 = HEX_4;
			4'd5: HEX3 = HEX_5;
			4'd6: HEX3 = HEX_6;
			4'd7: HEX3 = HEX_7;
			4'd8: HEX3 = HEX_8;
			4'd9: HEX3 = HEX_9;
			4'd10: HEX3 = HEX_10;
			4'd11: HEX3 = HEX_11;
			4'd12: HEX3 = HEX_12;
			4'd13: HEX3 = HEX_13;
			4'd14: HEX3 = HEX_14;
			4'd15: HEX3 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[2]) begin
			case(macout[2][15:12])
			4'd0: HEX3 = HEX_0;
			4'd1: HEX3 = HEX_1;
			4'd2: HEX3 = HEX_2;
			4'd3: HEX3 = HEX_3;
			4'd4: HEX3 = HEX_4;
			4'd5: HEX3 = HEX_5;
			4'd6: HEX3 = HEX_6;
			4'd7: HEX3 = HEX_7;
			4'd8: HEX3 = HEX_8;
			4'd9: HEX3 = HEX_9;
			4'd10: HEX3 = HEX_10;
			4'd11: HEX3 = HEX_11;
			4'd12: HEX3 = HEX_12;
			4'd13: HEX3 = HEX_13;
			4'd14: HEX3 = HEX_14;
			4'd15: HEX3 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[3]) begin
			case(macout[3][15:12])
			4'd0: HEX3 = HEX_0;
			4'd1: HEX3 = HEX_1;
			4'd2: HEX3 = HEX_2;
			4'd3: HEX3 = HEX_3;
			4'd4: HEX3 = HEX_4;
			4'd5: HEX3 = HEX_5;
			4'd6: HEX3 = HEX_6;
			4'd7: HEX3 = HEX_7;
			4'd8: HEX3 = HEX_8;
			4'd9: HEX3 = HEX_9;
			4'd10: HEX3 = HEX_10;
			4'd11: HEX3 = HEX_11;
			4'd12: HEX3 = HEX_12;
			4'd13: HEX3 = HEX_13;
			4'd14: HEX3 = HEX_14;
			4'd15: HEX3 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[4]) begin
			case(macout[4][15:12])
			4'd0: HEX3 = HEX_0;
			4'd1: HEX3 = HEX_1;
			4'd2: HEX3 = HEX_2;
			4'd3: HEX3 = HEX_3;
			4'd4: HEX3 = HEX_4;
			4'd5: HEX3 = HEX_5;
			4'd6: HEX3 = HEX_6;
			4'd7: HEX3 = HEX_7;
			4'd8: HEX3 = HEX_8;
			4'd9: HEX3 = HEX_9;
			4'd10: HEX3 = HEX_10;
			4'd11: HEX3 = HEX_11;
			4'd12: HEX3 = HEX_12;
			4'd13: HEX3 = HEX_13;
			4'd14: HEX3 = HEX_14;
			4'd15: HEX3 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[5]) begin
			case(macout[5][15:12])
			4'd0: HEX3 = HEX_0;
			4'd1: HEX3 = HEX_1;
			4'd2: HEX3 = HEX_2;
			4'd3: HEX3 = HEX_3;
			4'd4: HEX3 = HEX_4;
			4'd5: HEX3 = HEX_5;
			4'd6: HEX3 = HEX_6;
			4'd7: HEX3 = HEX_7;
			4'd8: HEX3 = HEX_8;
			4'd9: HEX3 = HEX_9;
			4'd10: HEX3 = HEX_10;
			4'd11: HEX3 = HEX_11;
			4'd12: HEX3 = HEX_12;
			4'd13: HEX3 = HEX_13;
			4'd14: HEX3 = HEX_14;
			4'd15: HEX3 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[6]) begin
			case(macout[6][15:12])
			4'd0: HEX3 = HEX_0;
			4'd1: HEX3 = HEX_1;
			4'd2: HEX3 = HEX_2;
			4'd3: HEX3 = HEX_3;
			4'd4: HEX3 = HEX_4;
			4'd5: HEX3 = HEX_5;
			4'd6: HEX3 = HEX_6;
			4'd7: HEX3 = HEX_7;
			4'd8: HEX3 = HEX_8;
			4'd9: HEX3 = HEX_9;
			4'd10: HEX3 = HEX_10;
			4'd11: HEX3 = HEX_11;
			4'd12: HEX3 = HEX_12;
			4'd13: HEX3 = HEX_13;
			4'd14: HEX3 = HEX_14;
			4'd15: HEX3 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[7]) begin
			case(macout[7][15:12])
			4'd0: HEX3 = HEX_0;
			4'd1: HEX3 = HEX_1;
			4'd2: HEX3 = HEX_2;
			4'd3: HEX3 = HEX_3;
			4'd4: HEX3 = HEX_4;
			4'd5: HEX3 = HEX_5;
			4'd6: HEX3 = HEX_6;
			4'd7: HEX3 = HEX_7;
			4'd8: HEX3 = HEX_8;
			4'd9: HEX3 = HEX_9;
			4'd10: HEX3 = HEX_10;
			4'd11: HEX3 = HEX_11;
			4'd12: HEX3 = HEX_12;
			4'd13: HEX3 = HEX_13;
			4'd14: HEX3 = HEX_14;
			4'd15: HEX3 = HEX_15;
			endcase
		end
		else begin
			HEX3 = OFF;
		end
end

always @(*) begin
		if (state == DONE2 & SW[0]) begin
			case(macout[0][19:16])
			4'd0: HEX4 = HEX_0;
			4'd1: HEX4 = HEX_1;
			4'd2: HEX4 = HEX_2;
			4'd3: HEX4 = HEX_3;
			4'd4: HEX4 = HEX_4;
			4'd5: HEX4 = HEX_5;
			4'd6: HEX4 = HEX_6;
			4'd7: HEX4 = HEX_7;
			4'd8: HEX4 = HEX_8;
			4'd9: HEX4 = HEX_9;
			4'd10: HEX4 = HEX_10;
			4'd11: HEX4 = HEX_11;
			4'd12: HEX4 = HEX_12;
			4'd13: HEX4 = HEX_13;
			4'd14: HEX4 = HEX_14;
			4'd15: HEX4 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[1]) begin
			case(macout[1][19:16])
			4'd0: HEX4 = HEX_0;
			4'd1: HEX4 = HEX_1;
			4'd2: HEX4 = HEX_2;
			4'd3: HEX4 = HEX_3;
			4'd4: HEX4 = HEX_4;
			4'd5: HEX4 = HEX_5;
			4'd6: HEX4 = HEX_6;
			4'd7: HEX4 = HEX_7;
			4'd8: HEX4 = HEX_8;
			4'd9: HEX4 = HEX_9;
			4'd10: HEX4 = HEX_10;
			4'd11: HEX4 = HEX_11;
			4'd12: HEX4 = HEX_12;
			4'd13: HEX4 = HEX_13;
			4'd14: HEX4 = HEX_14;
			4'd15: HEX4 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[2]) begin
			case(macout[2][19:16])
			4'd0: HEX4 = HEX_0;
			4'd1: HEX4 = HEX_1;
			4'd2: HEX4 = HEX_2;
			4'd3: HEX4 = HEX_3;
			4'd4: HEX4 = HEX_4;
			4'd5: HEX4 = HEX_5;
			4'd6: HEX4 = HEX_6;
			4'd7: HEX4 = HEX_7;
			4'd8: HEX4 = HEX_8;
			4'd9: HEX4 = HEX_9;
			4'd10: HEX4 = HEX_10;
			4'd11: HEX4 = HEX_11;
			4'd12: HEX4 = HEX_12;
			4'd13: HEX4 = HEX_13;
			4'd14: HEX4 = HEX_14;
			4'd15: HEX4 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[3]) begin
			case(macout[3][19:16])
			4'd0: HEX4 = HEX_0;
			4'd1: HEX4 = HEX_1;
			4'd2: HEX4 = HEX_2;
			4'd3: HEX4 = HEX_3;
			4'd4: HEX4 = HEX_4;
			4'd5: HEX4 = HEX_5;
			4'd6: HEX4 = HEX_6;
			4'd7: HEX4 = HEX_7;
			4'd8: HEX4 = HEX_8;
			4'd9: HEX4 = HEX_9;
			4'd10: HEX4 = HEX_10;
			4'd11: HEX4 = HEX_11;
			4'd12: HEX4 = HEX_12;
			4'd13: HEX4 = HEX_13;
			4'd14: HEX4 = HEX_14;
			4'd15: HEX4 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[4]) begin
			case(macout[4][19:16])
			4'd0: HEX4 = HEX_0;
			4'd1: HEX4 = HEX_1;
			4'd2: HEX4 = HEX_2;
			4'd3: HEX4 = HEX_3;
			4'd4: HEX4 = HEX_4;
			4'd5: HEX4 = HEX_5;
			4'd6: HEX4 = HEX_6;
			4'd7: HEX4 = HEX_7;
			4'd8: HEX4 = HEX_8;
			4'd9: HEX4 = HEX_9;
			4'd10: HEX4 = HEX_10;
			4'd11: HEX4 = HEX_11;
			4'd12: HEX4 = HEX_12;
			4'd13: HEX4 = HEX_13;
			4'd14: HEX4 = HEX_14;
			4'd15: HEX4 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[5]) begin
			case(macout[5][19:16])
			4'd0: HEX4 = HEX_0;
			4'd1: HEX4 = HEX_1;
			4'd2: HEX4 = HEX_2;
			4'd3: HEX4 = HEX_3;
			4'd4: HEX4 = HEX_4;
			4'd5: HEX4 = HEX_5;
			4'd6: HEX4 = HEX_6;
			4'd7: HEX4 = HEX_7;
			4'd8: HEX4 = HEX_8;
			4'd9: HEX4 = HEX_9;
			4'd10: HEX4 = HEX_10;
			4'd11: HEX4 = HEX_11;
			4'd12: HEX4 = HEX_12;
			4'd13: HEX4 = HEX_13;
			4'd14: HEX4 = HEX_14;
			4'd15: HEX4 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[6]) begin
			case(macout[6][19:16])
			4'd0: HEX4 = HEX_0;
			4'd1: HEX4 = HEX_1;
			4'd2: HEX4 = HEX_2;
			4'd3: HEX4 = HEX_3;
			4'd4: HEX4 = HEX_4;
			4'd5: HEX4 = HEX_5;
			4'd6: HEX4 = HEX_6;
			4'd7: HEX4 = HEX_7;
			4'd8: HEX4 = HEX_8;
			4'd9: HEX4 = HEX_9;
			4'd10: HEX4 = HEX_10;
			4'd11: HEX4 = HEX_11;
			4'd12: HEX4 = HEX_12;
			4'd13: HEX4 = HEX_13;
			4'd14: HEX4 = HEX_14;
			4'd15: HEX4 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[7]) begin
			case(macout[7][19:16])
			4'd0: HEX4 = HEX_0;
			4'd1: HEX4 = HEX_1;
			4'd2: HEX4 = HEX_2;
			4'd3: HEX4 = HEX_3;
			4'd4: HEX4 = HEX_4;
			4'd5: HEX4 = HEX_5;
			4'd6: HEX4 = HEX_6;
			4'd7: HEX4 = HEX_7;
			4'd8: HEX4 = HEX_8;
			4'd9: HEX4 = HEX_9;
			4'd10: HEX4 = HEX_10;
			4'd11: HEX4 = HEX_11;
			4'd12: HEX4 = HEX_12;
			4'd13: HEX4 = HEX_13;
			4'd14: HEX4 = HEX_14;
			4'd15: HEX4 = HEX_15;
			endcase
		end
		else begin
			HEX4 = OFF;
		end
end

always @(*) begin
		if (state == DONE2 & SW[0]) begin
			case(macout[0][23:20])
			4'd0: HEX5 = HEX_0;
			4'd1: HEX5 = HEX_1;
			4'd2: HEX5 = HEX_2;
			4'd3: HEX5 = HEX_3;
			4'd4: HEX5 = HEX_4;
			4'd5: HEX5 = HEX_5;
			4'd6: HEX5 = HEX_6;
			4'd7: HEX5 = HEX_7;
			4'd8: HEX5 = HEX_8;
			4'd9: HEX5 = HEX_9;
			4'd10: HEX5 = HEX_10;
			4'd11: HEX5 = HEX_11;
			4'd12: HEX5 = HEX_12;
			4'd13: HEX5 = HEX_13;
			4'd14: HEX5 = HEX_14;
			4'd15: HEX5 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[1]) begin
			case(macout[1][23:20])
			4'd0: HEX5 = HEX_0;
			4'd1: HEX5 = HEX_1;
			4'd2: HEX5 = HEX_2;
			4'd3: HEX5 = HEX_3;
			4'd4: HEX5 = HEX_4;
			4'd5: HEX5 = HEX_5;
			4'd6: HEX5 = HEX_6;
			4'd7: HEX5 = HEX_7;
			4'd8: HEX5 = HEX_8;
			4'd9: HEX5 = HEX_9;
			4'd10: HEX5 = HEX_10;
			4'd11: HEX5 = HEX_11;
			4'd12: HEX5 = HEX_12;
			4'd13: HEX5 = HEX_13;
			4'd14: HEX5 = HEX_14;
			4'd15: HEX5 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[2]) begin
			case(macout[2][23:20])
			4'd0: HEX5 = HEX_0;
			4'd1: HEX5 = HEX_1;
			4'd2: HEX5 = HEX_2;
			4'd3: HEX5 = HEX_3;
			4'd4: HEX5 = HEX_4;
			4'd5: HEX5 = HEX_5;
			4'd6: HEX5 = HEX_6;
			4'd7: HEX5 = HEX_7;
			4'd8: HEX5 = HEX_8;
			4'd9: HEX5 = HEX_9;
			4'd10: HEX5 = HEX_10;
			4'd11: HEX5 = HEX_11;
			4'd12: HEX5 = HEX_12;
			4'd13: HEX5 = HEX_13;
			4'd14: HEX5 = HEX_14;
			4'd15: HEX5 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[3]) begin
			case(macout[3][23:20])
			4'd0: HEX5 = HEX_0;
			4'd1: HEX5 = HEX_1;
			4'd2: HEX5 = HEX_2;
			4'd3: HEX5 = HEX_3;
			4'd4: HEX5 = HEX_4;
			4'd5: HEX5 = HEX_5;
			4'd6: HEX5 = HEX_6;
			4'd7: HEX5 = HEX_7;
			4'd8: HEX5 = HEX_8;
			4'd9: HEX5 = HEX_9;
			4'd10: HEX5 = HEX_10;
			4'd11: HEX5 = HEX_11;
			4'd12: HEX5 = HEX_12;
			4'd13: HEX5 = HEX_13;
			4'd14: HEX5 = HEX_14;
			4'd15: HEX5 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[4]) begin
			case(macout[4][23:20])
			4'd0: HEX5 = HEX_0;
			4'd1: HEX5 = HEX_1;
			4'd2: HEX5 = HEX_2;
			4'd3: HEX5 = HEX_3;
			4'd4: HEX5 = HEX_4;
			4'd5: HEX5 = HEX_5;
			4'd6: HEX5 = HEX_6;
			4'd7: HEX5 = HEX_7;
			4'd8: HEX5 = HEX_8;
			4'd9: HEX5 = HEX_9;
			4'd10: HEX5 = HEX_10;
			4'd11: HEX5 = HEX_11;
			4'd12: HEX5 = HEX_12;
			4'd13: HEX5 = HEX_13;
			4'd14: HEX5 = HEX_14;
			4'd15: HEX5 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[5]) begin
			case(macout[5][23:20])
			4'd0: HEX5 = HEX_0;
			4'd1: HEX5 = HEX_1;
			4'd2: HEX5 = HEX_2;
			4'd3: HEX5 = HEX_3;
			4'd4: HEX5 = HEX_4;
			4'd5: HEX5 = HEX_5;
			4'd6: HEX5 = HEX_6;
			4'd7: HEX5 = HEX_7;
			4'd8: HEX5 = HEX_8;
			4'd9: HEX5 = HEX_9;
			4'd10: HEX5 = HEX_10;
			4'd11: HEX5 = HEX_11;
			4'd12: HEX5 = HEX_12;
			4'd13: HEX5 = HEX_13;
			4'd14: HEX5 = HEX_14;
			4'd15: HEX5 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[6]) begin
			case(macout[6][23:20])
			4'd0: HEX5 = HEX_0;
			4'd1: HEX5 = HEX_1;
			4'd2: HEX5 = HEX_2;
			4'd3: HEX5 = HEX_3;
			4'd4: HEX5 = HEX_4;
			4'd5: HEX5 = HEX_5;
			4'd6: HEX5 = HEX_6;
			4'd7: HEX5 = HEX_7;
			4'd8: HEX5 = HEX_8;
			4'd9: HEX5 = HEX_9;
			4'd10: HEX5 = HEX_10;
			4'd11: HEX5 = HEX_11;
			4'd12: HEX5 = HEX_12;
			4'd13: HEX5 = HEX_13;
			4'd14: HEX5 = HEX_14;
			4'd15: HEX5 = HEX_15;
			endcase
		end
		else if (state == DONE2 & SW[7]) begin
			case(macout[7][23:20])
			4'd0: HEX5 = HEX_0;
			4'd1: HEX5 = HEX_1;
			4'd2: HEX5 = HEX_2;
			4'd3: HEX5 = HEX_3;
			4'd4: HEX5 = HEX_4;
			4'd5: HEX5 = HEX_5;
			4'd6: HEX5 = HEX_6;
			4'd7: HEX5 = HEX_7;
			4'd8: HEX5 = HEX_8;
			4'd9: HEX5 = HEX_9;
			4'd10: HEX5 = HEX_10;
			4'd11: HEX5 = HEX_11;
			4'd12: HEX5 = HEX_12;
			4'd13: HEX5 = HEX_13;
			4'd14: HEX5 = HEX_14;
			4'd15: HEX5 = HEX_15;
			endcase
		end
		else begin
			HEX5 = OFF;
		end
end

assign LEDR = {{8{1'b0}}, state};

endmodule