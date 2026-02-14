// written by colin
// refernced for testing purposes
`timescale 1 ps / 1 ps
module convolution_tb();
    
    reg clk;
    reg rst_n;
    reg [11:0] data;
    reg valid;
    reg [10:0] x_cont, y_cont;
    wire [11:0] oRed, oGreen, oBlue;
    wire oDVAL;

    // parameters
    localparam ROW_LENGTH = 4;
    localparam ROWS = 4;
    localparam COLS = ROW_LENGTH;
    
    // test data and golden reference storage
    logic signed [11:0] img [0:ROWS-1][0:COLS-1];
    logic [11:0] golden_reference [0:ROWS-1][0:COLS-1];

    // variables for tracking expected output
    integer r, c;
    reg [11:0] expected_prev;
    reg expected_prev_valid;
    integer expected_prev_r;
    integer expected_prev_c;

    // task to construct the golden reference output based on Sobel edge detection (matches image_processing_module)
    task automatic construct_golden;
        integer i, j;
        logic signed [15:0] Gx, Gy;
        logic [15:0] mag;
        logic [11:0] a00, a01, a02, a10, a11, a12, a20, a21, a22;
        begin
            // Compute the Sobel convolution for each pixel, handling borders by outputting zero
            for (i = 0; i < ROWS; i = i + 1) begin
                for (j = 0; j < COLS; j = j + 1) begin
                    if (i < 2 || j < 2) begin
                        golden_reference[i][j] = 12'd0; // zero padding for borders
                    end else begin
                        // 3x3 neighborhood (a00 top-left .. a22 bottom-right)
                        a00 = img[i-2][j-2]; a01 = img[i-2][j-1]; a02 = img[i-2][j];
                        a10 = img[i-1][j-2]; a11 = img[i-1][j-1]; a12 = img[i-1][j];
                        a20 = img[i][j-2];   a21 = img[i][j-1];   a22 = img[i][j];
                        
                        // Sobel Gx (horizontal gradient)
                        Gx = -$signed({1'b0,a00}) - 2*$signed({1'b0,a10}) - $signed({1'b0,a20})
                           +  $signed({1'b0,a02}) + 2*$signed({1'b0,a12}) + $signed({1'b0,a22});
                        
                        // Sobel Gy (vertical gradient)
                        Gy = -$signed({1'b0,a00}) - 2*$signed({1'b0,a01}) - $signed({1'b0,a02})
                           +  $signed({1'b0,a20}) + 2*$signed({1'b0,a21}) + $signed({1'b0,a22});
                        
                        // Magnitude = |Gx| + |Gy|
                        mag = (Gx[15] ? -Gx : Gx) + (Gy[15] ? -Gy : Gy);
                        
                        // Output is mag[15:4] (matches oRed in image_processing_module)
                        golden_reference[i][j] = mag[15:4];
                    end
                end
            end
        end
    endtask
    
    // dut instantiation
    image_processing_module dut(
        .iCLK(clk),
        .iRST(rst_n),
        .iDATA(data),
        .iDVAL(valid),
        .oRed(oRed),
        .oGreen(oGreen),
        .oBlue(oBlue),
        .oDVAL(oDVAL),
        .iX_Cont(x_cont),
        .iY_Cont(y_cont)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        data = 0;
        valid = 0;
        x_cont = 0;
        y_cont = 0;

        // Initialize the input image with a simple pattern
        for (r = 0; r < ROWS; r = r + 1) begin
            for (c = 0; c < COLS; c = c + 1) begin
                img[r][c] = r * COLS + c;
            end
        end

        construct_golden(); // Compute the golden reference output based on the Sobel operation

        repeat (2) @(posedge clk);
        rst_n = 1; // reset sequence
        repeat (2) @(posedge clk);

        expected_prev = 12'd0;
        expected_prev_valid = 1'b0;
        expected_prev_r = 0;
        expected_prev_c = 0;

        for (r = 0; r < ROWS; r = r + 1) begin
            for (c = 0; c < COLS; c = c + 1) begin
                @(posedge clk);
                valid <= 1'b1;
                data <= img[r][c];
                x_cont <= c;
                y_cont <= r;

                if (expected_prev_valid) begin  // Check the output against the expected value from the golden reference
                    if (oRed !== expected_prev) begin
                        $error("Mismatch r=%0d c=%0d exp=%0d got=%0d",
                               expected_prev_r, expected_prev_c, expected_prev, oRed);
                    end
                end

                if (r >= 2 && c >= 2) begin
                    expected_prev = golden_reference[r][c];
                    expected_prev_valid = 1'b1;
                    expected_prev_r = r;
                    expected_prev_c = c;
                end else begin
                    expected_prev = 12'd0;
                    expected_prev_valid = 1'b0;
                end
            end
        end

        @(posedge clk); // last one
        if (expected_prev_valid) begin
            if (oRed !== expected_prev) begin
                $error("Mismatch r=%0d c=%0d exp=%0d got=%0d",
                       expected_prev_r, expected_prev_c, expected_prev, oRed);
            end
        end
        valid <= 1'b0;

        $stop;

    end

    always #5 clk = ~clk;
endmodule