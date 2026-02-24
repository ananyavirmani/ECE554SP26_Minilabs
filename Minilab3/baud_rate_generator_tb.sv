module baud_rate_generator_tb();

    // DUT interface
    logic clk;
    logic rst;
    logic [7:0] db_high;
    logic [7:0] db_low;
    logic wr_low;
    logic wr_high;
    logic baud_en;

    // Instantiate DUT
    baud_rate_generator IDUT (
        .clk(clk),
        .rst(rst),
        .wr_low(wr_low),
        .wr_high(wr_high),
        .db_high(db_high),
        .db_low(db_low),
        .baud_en(baud_en)
    );

    // -----------------------------------------
    // Tasks
    // -----------------------------------------

    task automatic write_low(input [7:0] value);

        @(posedge clk);
        db_data = value;
        wr_low = 1;
        @(posedge clk);
        wr_low = 0;

    endtask

    task automatic write_high(input [7:0] value);

        @(posedge clk);
        db_data = value;
        wr_high = 1;
        @(posedge clk);
        wr_high = 0;

    endtask

    task automatic test_divisor(input [15:0] divisor);
        int cycles = 0;

        $display("\n--- Testing divisor 0x%04h (%0d) ---", divisor, divisor);

        // Load divisor
        write_low(divisor[7:0]);
        write_high(divisor[15:8]);

        // Wait one cycle for DUT to latch
        @(posedge clk);

        // Confirm load
        $display("Loaded divisor = 0x%04h", dut.divisor);

        // Count cycles until first baud_en pulse
        cycles = 0;
        while (baud_en == 0) begin
            @(posedge clk);
            cycles++;
        end

        $display("First baud_en pulse after %0d cycles", cycles);
        $display("Expected ≈ divisor + 1 = %0d\n", divisor + 1);
    endtask



    // -----------------------------------------
    // Test sequence
    // -----------------------------------------
    initial begin
        clk = 0;
        rst = 1;
        wr_low = 0;
        wr_high = 0;
        db_low = 0;
        db_high = 0;

        repeat (3) @(posedge clk);
        rst = 0;

        // divisor = (50e6 / (16 * baud)) - 1
        test_divisor(16'h00A2);

        $display("Simulation complete.");
        $stop();
    end


    always #10 clk = ~clk;

endmodule

