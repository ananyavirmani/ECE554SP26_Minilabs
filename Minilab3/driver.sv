//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    
// Design Name: 
// Module Name:    driver 
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
module driver (
    input wire clk,
    input wire rst,
    input wire [1:0] br_cfg,
    output logic iocs,
    output logic iorw,
    input wire rda,
    input wire tbr,
    output logic [1:0] ioaddr,
    inout wire [7:0] databus
);
    typedef enum logic [1:0] { LOAD_LO, LOAD_HI, RECV, SEND } state_t;
    state_t state, next_state;
    always_ff @(posedge clk, posedge rst) begin
        if (rst)
            state <= LOAD_LO;
        else
            state <= next_state;
    end

    logic [7:0] fifo;
    logic store_fifo;
    always_ff @(posedge clk) begin
        if (store_fifo)
            fifo <= databus;
    end

    logic [7:0] odata;
    logic load_fifo;
    assign databus = load_fifo ? odata : 8'hzz;

    localparam logic [1:0] ADDR_DATA = 2'b00;
    localparam logic [1:0] ADDR_STATUS = 2'b01;
    localparam logic [1:0] ADDR_DIV_LO = 2'b10;
    localparam logic [1:0] ADDR_DIV_HI = 2'b11;

    localparam logic [7:0] DIV_HI [0:3] = '{8'h02, 8'h01, 8'h00, 8'h00};
    localparam logic [7:0] DIV_LO [0:3] = '{8'h8b, 8'h44, 8'ha2, 8'h51};

    always_comb begin
        next_state = state;
        iocs = 1'b0;
        iorw = 1'bx;
        ioaddr = 2'hx;
        odata = 8'h00;
        store_fifo = 1'b0;
        load_fifo = 1'b0;

        case (state)
            LOAD_LO: begin
                iocs = 1'b1;
                iorw = 1'b0;
                ioaddr = ADDR_DIV_LO;
                odata = DIV_LO[br_cfg];
                load_fifo = 1'b1;

                next_state = LOAD_HI;
            end
            LOAD_HI: begin
                iocs = 1'b1;
                iorw = 1'b0;
                ioaddr = ADDR_DIV_HI;
                odata = DIV_HI[br_cfg];
                load_fifo = 1'b1;

                next_state = RECV;
            end
            RECV: begin
                if (rda) begin
                    iocs = 1'b1;
                    iorw = 1'b1;
                    ioaddr = ADDR_DATA;
                    store_fifo = 1'b1;
                    next_state = SEND;
                end
            end
            SEND: begin
                if (tbr) begin
                    iocs = 1'b1;
                    iorw = 1'b0;
                    ioaddr = ADDR_DATA;
                    odata = fifo;
                    load_fifo = 1'b1;
                    next_state = RECV;
                end
            end
            default: next_state = LOAD_HI;
        endcase
    end
endmodule