module shift_reg #(
    parameter int WIDTH = 1,
    parameter int DEPTH = 1
) (
    input  logic               iCLK,
    input  logic               iRST,
    input  logic [WIDTH - 1:0] i_data,
    input  logic               i_shift,
    output logic [WIDTH - 1:0] o_data
);
    logic [DEPTH - 1:0][WIDTH - 1:0] mem;

    always @(posedge iCLK, negedge iRST) begin
        if (!iRST)
            mem[0] <= '0;
        else if (i_shift)
            mem[0] <= i_data;

    end

    genvar i;
    generate
    for (i = 1; i < DEPTH; i = i + 1) begin : shift
        always @(posedge iCLK, negedge iRST) begin
            if (!iRST)
                mem[i] <= '0;
            else if (i_shift)
                mem[i] <= mem[i - 1];
        end
    end
    endgenerate

    assign o_data = mem[DEPTH - 1];
endmodule