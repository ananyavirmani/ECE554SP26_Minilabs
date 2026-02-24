module baud_rate_generator(
    input clk,
    input rst,
    input wr_low,
    input wr_high,
    input [7:0] db_high,
    input [7:0] db_low,
    output logic baud_en
);

logic [15:0] divisor;
logic [15:0] store;

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        divisor <= 16'h0146;
        baud_en <= 1'b0;

    end else if (divisor == 16'h0000) begin
        divisor <= store;
        baud_en <= 1'b1;

    end else begin
        baud_en <= 1'b0;
        if (wr_low)
            store[7:0] <= db_low;

        else if (wr_high)
            store[15:8] <= db_high;

        else
            divisor <= divisor - 1'b1;
    end 
        
end


endmodule