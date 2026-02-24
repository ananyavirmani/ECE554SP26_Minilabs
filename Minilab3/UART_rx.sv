module UART_rx(
	input clk,						// Clock
	input rst_n,					// Reset
	input RX,						// Serial data input
	input clr_rdy,					// Knocks down rdy when asserted
    input baud_en,					// Asserted at the baud rate; used to time the sampling of RX
	output logic [7:0]rx_data,		// Byte received
	output logic rdy				// Asserted when byte received; stays high until start bit of next byte starts, or until clr_rdy asserted
);

	// Declare intermediate signals
	logic [3:0]bit_cnt;
	logic [11:0]baud_cnt;
	logic [8:0]rx_shift_reg;
	logic shift;
	logic start;
	logic set_rdy;
	logic receiving;
	logic RX_FF1;
	logic meta_free_RX;


	//accounting meta-stability by double flopping RX
	always_ff @(posedge clk, negedge rst_n) begin
		//prestting the flops to 1 to ensure no false edge is detected in SM
		if (!rst_n) begin
			RX_FF1 <= 1'b1;
			meta_free_RX <= 1'b1;
		end else begin
			RX_FF1 <= RX;
			meta_free_RX <= RX_FF1;
		end
	end
	
	
	//SM : design
  /*																	 	                        .........................
	*				--meta_free_RX--									    	               -----.bit_cnt!=4'hA/receiving.----
	* .......		|			   |											               |    .........................	|
	* .rst_n.---> ////////<---------           ...............................            ///////////       					|
	* .......	 //idle//----------------------.!meta_free_RX/start,receiving.----------> //recieve// <--------------------------
	*		 -->////////	                   ...............................  	      ///////////----
	*		 |																	  						|
	*		 |					.......................  					 	  						|
	*		 -------------------.bit_cnt==4'hA/set_rdy.--------------------------------------------------
	*							.......................	
	*	
  */
	
	// Declare states
	typedef enum reg {idle,recieve} state_t;
	state_t state, nxt_state;
	
	// Flip flop for state transitions and reset
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= idle;
		else 
			state <= nxt_state;
	
	// State machine logic
	always_comb begin
		// Default values
		nxt_state = idle;
		start = 1'b0;
		receiving = 1'b0;
		set_rdy = 1'b0;
	
		// State logic
		case(state)
			// idle state: if byte is not recieved move to receive state
			idle: if (!meta_free_RX) begin
					nxt_state = recieve;
					start = 1'b1;
					receiving = 1'b1;
				  end

			// receive state: as long as no. of bits received is not 10, stay in this state and keep receiving
			recieve : if (bit_cnt != 4'hA) begin
						receiving = 1'b1;
						nxt_state = recieve;
				  end else
						set_rdy = 1'b1;
		endcase
	end
	
	
	//shift reg FF
	always_ff @(posedge clk)
		if (shift)
			rx_shift_reg <= {meta_free_RX,rx_shift_reg[8:1]};
			
			
	//data shifted in during the receiving of the transmitted data from transmitor
	assign rx_data = rx_shift_reg[7:0];
	
	//asserting shift after baud_cnt hits 0
	assign shift = baud_en && receiving;
	
	//FF to count bits shifted in
	always_ff @(posedge clk)
		if (start)
			bit_cnt <= 4'h0;
		else if (shift)
			bit_cnt <= bit_cnt + 1'b1;
	
	
	//SR FF
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			rdy <= 1'b0;
		else if (start || clr_rdy)
			rdy <= 1'b0;
		else if (set_rdy)
			rdy <= 1'b1;

endmodule
