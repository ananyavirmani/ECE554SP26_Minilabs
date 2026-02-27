module baud_rate_generator(
    input clk,
    input rst,
    input wr_low,
    input wr_high,
    input [7:0] db_data,
    output logic baud_en
);

logic [15:0] divisor;
logic [15:0] store;
logic [1:0] store_data_valid;

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        store <= 16'h0000;
        divisor <= 16'h0146;
        baud_en <= 1'b0;
        store_data_valid <= 2'b0;

    end else if (divisor == 16'h0000 && store_data_valid == 2'b11) begin
        divisor <= store;
        baud_en <= 1'b1;

    end  else if (divisor == 16'h0000) begin
        divisor <= 16'h0146;
        baud_en <= 1'b1;

    end else begin
        baud_en <= 1'b0;
        if (wr_low) begin
            store[7:0] <= db_data;
            store_data_valid[0] <= 1'b1;
            
        end else if (wr_high) begin
            store[15:8] <= db_data;
            store_data_valid[1] <= 1'b1;

        end else begin
            divisor <= divisor - 1'b1;
        end

    end

end


endmodule