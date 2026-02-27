module UART_tx (
	input clk,					// Clock
	input rst,				// Reset
	input trmt,					// Asserted for 1 clock to initiate transmission
	input [7:0]tx_data,			// Byte to transmit
    input baud_en,
	output logic tx_done,		// Asserted when byte is done transmitting; stays high till next byte transmitted
	output logic TX				// Serial data output
);
	
	// Declare intermediate signals
	logic [8:0]tx_shift_reg;
	logic [11:0]baud_cnt;
	logic [3:0]bit_cnt;
	logic init;
	logic shift;
	logic transmitting;
	logic set_done;
	

	//SM : design
  /*																	 	  ............................
	*				--!trmt--									    	  ----.bit_cnt!=4'hA/transmitting.----
	* .......		|		|											  |	  ............................	 |
	* .rst.---> ////////<--   ........................             ////////////       					 |
	* .......	 //idle//-------.trmt/init,transmitting.----------> //transmit// <----------------------------
	*		 -->////////	    ........................  	       ////////////----------
	*		 |																	  		|
	*		 |					........................  					 	  		|
	*		 -------------------.bit_cnt==4'hA/set_done.---------------------------------
	*							........................	
	*	
  */
	
	// Declare states
	typedef enum reg {idle, transmit} state_t;
	state_t state, nxt_state;

	// Flip flop for state transition and reset
	always_ff @(posedge clk, posedge rst)
		if (rst)
			state <= idle;
		else
			state <= nxt_state;
	
	// State machine logic
	always_comb begin
		// Default values
		nxt_state = idle;
		transmitting = 1'b0;
		init = 1'b0;
		set_done = 1'b0;

		// State logic
		case(state)
			// idle state: stay in this state until trmt is asserted, then move to transmit
			idle: if (trmt) begin
					nxt_state = transmit;
					init = 1'b1;
					transmitting = 1'b1;
				  end

			// transmit state: as long as bit_cnt (no. of bits transmitted) is not 10, keep transmitting, otherwise assert set_done
			transmit : if (bit_cnt != 4'hA) begin
						 transmitting = 1'b1;
						 nxt_state = transmit;
				   end else
						 set_done = 1'b1;
		endcase
		
	end


	//shift reg FF
	always_ff @(posedge clk, posedge rst)
		if (rst)
			tx_shift_reg <= 9'h1FF;
		else if (init)
			tx_shift_reg <= {tx_data,1'b0};
		else if (shift)
			tx_shift_reg <= {1'b1,tx_shift_reg[8:1]};
		
	
	//shifted bit out to transmit
	assign TX = tx_shift_reg[0];
			
	//asserting shift after 2064 baud count
	assign shift = baud_en && transmitting;
	
	
	//FF to count bits shifted out
	always_ff @(posedge clk)
		if (init)
			bit_cnt <= 4'h0;
		else if (shift)
			bit_cnt <= bit_cnt + 1'b1;
	
	
	//SR FF
	always_ff @(posedge clk)
		if (rst)
			tx_done <= 1'b0;
		else if (init)
			tx_done <= 1'b0;
		else if (set_done)
			tx_done <= 1'b1;

endmodule
