module UART_tb();
	
	logic clk;				// Clock
	logic rst;			// Asynch reset
	logic trmt;				// Asserted for 1 clock to initiate transmission
	logic TX;				// Serial data output
	logic [7:0]tx_data;		// Byte to transmit
	logic tx_done;			// Asserted when byte is done transmitting; stays high till next byte transmitted
	logic clr_rdy;			// Knocks down rdy when asserted
	logic [7:0]rx_data;		// Byte received
	logic rdy;				// Asserted when byte received; stays high until start bit of next byte starts, or until clr_rdy asserted
	
	logic test_fail = 0;	// innocent until proven guilty (test fail vector)
	
	
	//intantiating TX
	UART_tx iUART_tx (.clk(clk), .rst(rst), .trmt(trmt), .baud_en(baud_en), .tx_data(tx_data), .tx_done(tx_done), .TX(TX));
	
	//intantiating RX
	UART_rx iUART_rx (.clk(clk), .rst(rst), .RX(TX), .clr_rdy(clr_rdy), .rx_data(rx_data), .rdy(rdy), .baud_en(baud_en));

    baud_rate_generator i_baud_rate_generator (
        .clk(clk),
        .rst(rst),
        .db_high(8'h00),
        .db_low(8'hA2),
        .baud_en(baud_en)
    );
	
	initial begin
		// Default values to 0
		clk = 0;
		rst = 1;
		clr_rdy = 0;
		
		@(negedge clk);
		tx_data = 8'h59;	// data 1 to be transmitted
		
		@(posedge clk);
		@(negedge clk);
		rst = 0;			// deassert asynch reset
		trmt = 1;			// assert transmit
		
		@(posedge clk);
		
		//trmt deasserted after 1 clk cycle
		trmt = 0;
		
		@(posedge tx_done)

		//checks if RX sets the rdy flag
		if (rdy !== 1)		
			test_fail = 1;

		//checks if the transmitted data and the recieved data is equivalent
		if (tx_data !== rx_data)	
			test_fail = 1;
			
		repeat(3) @(posedge clk);
		
		clr_rdy = 1;		// remove current rdy data
		tx_data = 8'hAA;	// data 2 to be transmitted
		
		@(posedge clk);
		
		clr_rdy = 0;		// deassert clr_rdy
		trmt = 1;			// assert transmit
		
		@(posedge clk);
		
		//trmt deasserted after 1 clk cycle
		trmt = 0;

		@(posedge tx_done)

		//checks if RX sets the rdy flag
		if (rdy !== 1)
			test_fail = 1;

		//checks if the transmitted data and the recieved data is equivalent
		if (tx_data !== rx_data)
			test_fail = 1;

		// Self-check
		if (test_fail)
			$display("Test failed.");
		else
			$display("YAHOO! Test passed.");

		
		$stop();
	end
	
	always
		#5 clk = ~clk; // Toggle clock every 5 time units

endmodule
