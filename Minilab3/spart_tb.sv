`timescale 1ns / 1ps

module spart_tb();

    // Inputs to SPART
    logic clk, rst;
    logic iocs, iorw;
    logic [1:0] ioaddr;
    
    // Bidirectional Bus Logic
    wire [7:0] databus;
    logic [7:0] databus_reg;
    logic driving_bus;

    // Outputs from SPART
    logic rda, tbr;
    logic txd;
    logic rxd; // We can loop txd to rxd for a loopback test

    logic [7:0] recd_char; // To store received character for verification

    // Drive the bus only during a Write operation (IOR/W = 0)
    assign databus = databus_reg;

    // Instantiate the SPART module
    spart i_spart (
        .clk(clk),
        .rst(rst),
        .iocs(iocs),
        .iorw(iorw),
        .rda(rda),
        .tbr(tbr),
        .ioaddr(ioaddr),
        .databus(databus),
        .txd(txd),
        .rxd(txd)
    );

    // Test Sequence
    initial begin
        clk = 0;
        // Initialize signals
        rst = 1;
        iocs = 0;
        iorw = 1;
        ioaddr = 2'b00;
        driving_bus = 0;
        rxd = 1; // Idle state for UART is High

        // Release Reset
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // --- PHASE 1: LOAD BAUD RATE DIVISOR ---
        // Example: Divisor for 9600 baud at 50MHz is ~325 (0x0145) 
        
        // Write Low Byte (0x45) to DB(Low) 
        write_bus(2'b10, 8'h45); 
        
        // Write High Byte (0x01) to DB(High) 
        write_bus(2'b11, 8'h01);

        // --- PHASE 2: TRANSMIT A CHARACTER ---
        // Wait for Transmit Buffer Ready 
        wait(tbr == 1);
        
        // Write 'A' (0x41) to Transmit Buffer 
        write_bus(2'b00, 8'h41);
        
        $display("Character 'A' sent to Transmit Buffer.");

        // --- PHASE 3: RECEIVE (LOOPBACK) ---
        // In a real test, you'd feed serial data into rxd. 
        // For simplicity, we wait for a simulated reception.
        wait(rda == 1); // Only works if you've implemented the receiver logic

        read_bus(2'b00, recd_char); // Read received data

        $display("Simulation captured received data: %h (%c)", recd_char, recd_char);
        
        $stop;
    end

     // Clock Generation (e.g., 50MHz) 
    always #10 clk = ~clk; // Clock generation

    // Helper Task: Manual Processor Write 
    task automatic write_bus(input [1:0] addr, input [7:0] data);
        begin
            @(negedge clk);
            ioaddr = addr;
            iorw = 0;     // Write mode 
            databus_reg = data;
            driving_bus = 1;
            iocs = 1;      // Enable Chip Select 
            @(posedge clk);
            iocs = 0;
            driving_bus = 0;
            iorw = 1;     // Return to Read mode
        end
    endtask

    // Helper Task: Manual Processor Read 
    task automatic read_bus(input [1:0] addr, output [7:0] data);
        begin
            @(negedge clk);
            ioaddr = addr;
            iorw = 1;     // Read mode 
            iocs = 1;
            @(posedge clk);
            #1;
            data = databus;
            iocs = 0;
        end
    endtask


endmodule