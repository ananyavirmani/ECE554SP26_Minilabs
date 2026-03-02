module loop_tb ();

// Receiver Signals
logic clk;
logic rst;
logic rx_baud;  
logic line;
logic reset_valid;   // clears the valid flag
logic [7:0] o_data;
logic o_valid;

// Transmit Signals 
logic start;         // initiates a transaction 
logic [7:0] i_data;
logic tx_en;
logic busy;
logic wr_low;
logic wr_high;
logic [7:0] db_data;

// -----------------------------
// Module Instantiation
// -----------------------------
UART_rx iREC(
	.clk(clk),						
	.rst(rst),					
	.RX(line),						
	.clr_rdy(reset_valid),					
	.baud_en(baud_en),					
	.rx_data(o_data),		
	.rdy(o_valid)					
);

UART_tx iTRANS(
	.clk(clk),					
	.rst(rst),					
	.trmt(start),					
	.tx_data(i_data),			
  .baud_en(baud_en),
	.tx_done(),		
	.TX(line)				
);

// baud_rate_generator iBAUD_GEN(
//     .clk(clk),
//     .rst(rst),
//     .db_high(8'h00),
//     .db_low(8'h05),
//     .tx_en(tx_en),   // when we shift data onto the tx line
//     .rx_baud(rx_baud)   // when we sample data from the rx line
// );

baud_rate_generator iBAUD_GEN (
        .clk(clk),
        .rst(rst),
        // .wr_low(wr_low),
        // .wr_high(wr_high),
        .wr_en(wr_low || wr_high),
        .db_data(db_data),
        .baud_en(baud_en)
);

  // -----------------------------
  // Clock generation
  // -----------------------------
  initial clk = 1'b0;
  always #5 clk = ~clk;      // 100 MHz if timescale is 1ns/1ps (adjust as needed)


  task automatic write_low(input [7:0] value, input logic in_low);

      @(negedge clk);
      db_data = value;
      wr_low = in_low;
      @(negedge clk);
      wr_low = 0;

  endtask

  task automatic write_high(input [7:0] value, input logic in_high);

      @(negedge clk);
      db_data = value;
      wr_high = in_high;
      @(negedge clk);
      wr_high = 0;

  endtask
  // -----------------------------
  // Task: send one byte
  // -----------------------------
  task automatic send_byte(input logic [7:0] b);
    begin
      // wait until transmitter is idle
      @(posedge clk);
      while (busy) @(posedge clk);

      i_data <= b;
      start  <= 1'b1;
      @(posedge clk);
      start  <= 1'b0;
    end
  endtask

  // -----------------------------
  // Task: wait for a received byte and check it
  // -----------------------------
  task automatic expect_byte(input logic [7:0] expected);
    logic [7:0] got;
    begin
      // Wait for receiver to assert valid
      @(posedge clk);
      while (!o_valid) @(posedge clk);

      got = o_data;

      if (got !== expected) begin
        $error("UART LOOPBACK FAIL: expected 0x%02h, got 0x%02h", expected, got);
      end else begin
        $display("UART LOOPBACK PASS: received 0x%02h", got);
      end

      // Clear valid flag (pulse reset_valid if your receiver uses it that way)
      reset_valid <= 1'b1;
      @(posedge clk);
      reset_valid <= 1'b0;
    end
  endtask

  task automatic test_divisor(input [7:0] divisor, input logic in_high, input logic in_low);

      // $display("\n--- Testing divisor 0x%04h (%0d) ---", divisor, divisor);

      // Load divisor
      write_low(divisor, in_low);
      write_high(divisor, in_high);

      // Wait one cycle for DUT to latch
      @(posedge clk);

      // Confirm load
      $display("Loaded divisor = 0x%04h", iBAUD_GEN.store);

      // Count cycles until first baud_en pulse
      // cycles = 0;
      // while (baud_en == 0) begin
      //     @(posedge clk);
      //     cycles++;
      // end

      // $display("First baud_en pulse after %0d cycles", cycles);
      // $display("Expected ≈ divisor + 1 = %0d\n", divisor + 1);
  endtask


   // -----------------------------
  // Test sequence
  // -----------------------------
  initial begin
    // defaults
    start       = 1'b0;
    i_data      = 8'h00;
    reset_valid = 1'b0;
    wr_low     = 1'b0;
    wr_high    = 1'b0;

    // reset
    rst = 1'b1;
    repeat (10) @(posedge clk);
    rst = 1'b0;

    // test_divisor(16'h0146);

    // @(posedge iBAUD_GEN.load); // waits for new counter to load

    // Send one byte and verify loopback
    send_byte(8'h56);
    expect_byte(8'h56);

    test_divisor(o_data, 1'b1, wr_high);

    repeat (6) @(posedge clk);
    send_byte(8'h06);
    expect_byte(8'h06);

    test_divisor(o_data, wr_low, 1'b1);

     repeat (6) @(posedge clk);
    send_byte(8'hA5);
    expect_byte(8'hA5);

    // done
    $stop();
  end

endmodule