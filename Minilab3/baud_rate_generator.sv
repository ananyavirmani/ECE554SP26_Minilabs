module baud_rate_generator(
    input clk,
    input rst,
    input [7:0] db_high,
    input [7:0] db_low,
    output logic baud_en
);

logic [15:0] divisor;

// always_ff @(posedge clk /*or negedge rst*/) begin
//     if (rst)
//         divisor <= 16'h0145; // 50MHz / 2^4 * 9600
//     else
//         divisor <= {db_high, db_low};
// end

logic divisor_cnt; // How many bits?
logic load;

assign load = (divisor_cnt == 16'h0000);

always_ff @(posedge clk or posedge rst) begin
    if (rst)
        divisor_cnt <= 16'h0145;
    else if (load)
        divisor_cnt <= {db_high, db_low};
    else
        divisor_cnt <= divisor_cnt - 1'b1;
end

always_ff @(posedge clk or posedge rst) begin
    if (rst)
        baud_en <= 1'b0;
    else if (divisor_cnt == 16'h0000)
        baud_en <= 1'b1;
    else
        baud_en <= 1'b0;
end


endmodule