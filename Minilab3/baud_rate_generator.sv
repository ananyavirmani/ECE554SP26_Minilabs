module baud_rate_generator(
    input clk,
    input rst,
    input [7:0] db_high,
    input [7:0] db_low,
    output logic baud_en
);

logic [15:0] divisor;

logic load;

assign load = (divisor == 16'h0000);

always_ff @(posedge clk or posedge rst) begin
    if (rst)
        divisor <= 16'h0145;
    else if (load)
        divisor <= {db_high, db_low};
    else
        divisor <= divisor - 1'b1;
end

always_ff @(posedge clk or posedge rst) begin
    if (rst)
        baud_en <= 1'b0;
    else if (divisor == 16'h0000)
        baud_en <= 1'b1;
    else
        baud_en <= 1'b0;
end


endmodule