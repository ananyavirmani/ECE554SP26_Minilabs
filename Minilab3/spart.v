//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name: 
// Module Name:    spart 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module spart(
    input clk,
    input rst,
    input iocs,
    input iorw,
    output rda,
    output tbr,
    input [1:0] ioaddr,
    inout [7:0] databus,
    output txd,
    input rxd
    );

// internal regs/wires
wire [7:0] rx_data;
wire rx_ready;
wire tx_ready;
reg  tx_start;
reg  [7:0] tx_data;
wire [7:0] db_out;              // value to drive onto databus during read
wire drive_databus;             // enable driving databus
assign databus = drive_databus ? db_out : 8'bz;

//status register (not a reg just wires) consists of RDA and TBR in position 0 and 1 resp. reamaing 6 bits are 0.
assign rda = rx_ready;
assign tbr = tx_ready;

//mux to select either receive buffer or status register.
assign db_out = (iocs && iorw) ? 
                (ioaddr == 2'b00 ? rx_data : 
                    (ioaddr == 2'b01 ? {6'b0, tx_ready, rx_ready} : 8'h00)) 
                : 8'h00;

assign drive_databus = (iocs && iorw) ? 1'b1 : 1'b0;

// write capture (synchronous)
always @(posedge clk or posedge rst) begin
    if (rst) begin
        tx_start <= 1'b0;
        tx_data <= 8'h00;
    end else begin
        tx_start <= 1'b0; // default single-cycle pulse
        if (iocs && !iorw) begin      // write cycle detected (confirm polarity)
            if (ioaddr == 2'b00) begin
                tx_data <= databus;   // sample the bus
                tx_start <= 1'b1;     // pulse to start transmitter (one-cycle)
            end
        end
    end
end

// baud rate generator module instantiation
baud_rate_generator baud_generator (
    .clk(clk),
    .rst(rst),
    .wr_en(!iorw && ioaddr[1]),
    .db_data(databus),
    .baud_en(baud_en)
);

// Instantiate receiver and transmitter modules
UART_rx receiver (
    .clk(clk),
    .rst(rst),
    .RX(rxd),
    .clr_rdy(iocs && iorw && ioaddr == 2'b00),
    .baud_en(baud_en),
    .rx_data(rx_data),
    .rdy(rx_ready)
);
UART_tx transmitter (
    .clk(clk),
    .rst(rst),
    .trmt(tx_start),
    .tx_data(tx_data),
    .baud_en(baud_en),
    .TX(txd),
    .tx_done(tx_ready)
);

endmodule
