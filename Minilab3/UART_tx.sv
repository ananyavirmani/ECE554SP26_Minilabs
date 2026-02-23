module UART_tx (
    input  clk,
    input  rst_n,
    input  trmt,              // 1-cycle pulse to start
    input  baud_en,           // from BRG
    input  [7:0] tx_data,

    output logic tx_done,
    output logic TX
);

    // Registers
    logic [9:0] tx_shift_reg;   // start + 8 data + stop
    logic [3:0] bit_cnt;
    logic transmitting;
    logic init;
    logic set_done;

    typedef enum logic {idle, transmit} state_t;
    state_t state, nxt_state;

    //----------------------------------------
    // State Register
    //----------------------------------------
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n)
            state <= idle;
        else
            state <= nxt_state;

    //----------------------------------------
    // Next-State Logic
    //----------------------------------------
    always_comb begin
        nxt_state    = state;
        transmitting = 1'b0;
        init         = 1'b0;
        set_done     = 1'b0;

        case (state)

            idle: begin
                if (trmt) begin
                    nxt_state    = transmit;
                    init         = 1'b1;
                    transmitting = 1'b1;
                end
            end

            transmit: begin
                transmitting = 1'b1;

                if (bit_cnt == 4'd10) begin
                    set_done = 1'b1;
                    nxt_state = idle;
                end
            end

        endcase
    end

    //----------------------------------------
    // Shift Register
    //----------------------------------------
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n)
            tx_shift_reg <= 10'h3FF;  // idle = all 1s
        else if (init)
            tx_shift_reg <= {1'b1, tx_data, 1'b0}; // stop,data,start
        else if (baud_en && transmitting)
            tx_shift_reg <= {1'b1, tx_shift_reg[9:1]};

    assign TX = tx_shift_reg[0];

    //----------------------------------------
    // Bit Counter
    //----------------------------------------
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n)
            bit_cnt <= 4'd0;
        else if (init)
            bit_cnt <= 4'd0;
        else if (baud_en && transmitting)
            bit_cnt <= bit_cnt + 1'b1;

    //----------------------------------------
    // Done Flag
    //----------------------------------------
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n)
            tx_done <= 1'b0;
        else if (init)
            tx_done <= 1'b0;
        else
            tx_done <= set_done;

endmodule
