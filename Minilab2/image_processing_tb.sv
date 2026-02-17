`timescale 1ns / 1ps

module image_processing_tb ();

localparam int IMG_WIDTH = 1280;      // Use 6x6 image
localparam int IMG_HEIGHT = 6;

// Test image storage
logic [11:0] test_img [0:IMG_HEIGHT-1][0:IMG_WIDTH-1];

// Grayscale matrix storage (3x3 after decimation by coordinate gating)
logic [11:0] gray_matrix [0:2][0:2];
int gray_row_idx = 0, gray_col_idx = 0;

// Signals
logic iCLK, iRST;
logic [11:0] iDATA;
logic iDVAL;
logic [10:0] iX_Cont, iY_Cont;
logic [11:0] oRed, oGreen, oBlue;
logic oDVAL;

// Instantiate DUT
image_processing_module dut (
    .iCLK(iCLK),
    .iRST(iRST),
    .iDATA(iDATA),
    .iDVAL(iDVAL),
    .oRed(oRed),
    .oGreen(oGreen),
    .oBlue(oBlue),
    .oDVAL(oDVAL),
    .iX_Cont(iX_Cont),
    .iY_Cont(iY_Cont)
);


// Initialize test image - 6x6 pattern: 4 rows of 100, 2 rows of 500
task init_test_image();
    // Create test pattern:
    //     Col: 0   1   2   3   4   5
    // Row 0:  100 100 100 100 100 100
    // Row 1:  100 100 100 100 100 100
    // Row 2:  100 100 100 100 100 100
    // Row 3:  100 100 100 100 100 100  <- Transition at row 4
    // Row 4:  500 500 500 500 500 500
    // Row 5:  500 500 500 500 500 500
    
    for (int r = 0; r < IMG_HEIGHT; r = r + 1) begin
        for (int c = 0; c < IMG_WIDTH; c = c + 1) begin
            if (r < 4)
                test_img[r][c] = 12'd100;  // First 4 rows: dark
            else
                test_img[r][c] = 12'd500;  // Last 2 rows: bright
        end
    end
    
    $display("[TB] Test image (6x6):");
    $display("     Col: 0   1   2   3   4   5");
    for (int r = 0; r < IMG_HEIGHT; r = r + 1) begin
        $write("Row %d: ", r);
        for (int c = 0; c < IMG_WIDTH; c = c + 1) begin
            $write("%3d ", test_img[r][c]);
        end
        $display("");
    end
endtask

// Main test
initial begin
    // Initialize
    iCLK = 0;
    iRST = 0;
    iDATA = 0;
    iDVAL = 0;
    iX_Cont = 0;
    iY_Cont = 0;
    
    @(posedge iCLK);
    iRST = 1;
    
    $display("\n========================================");
    $display("  Simple Sobel Testbench (6x6 image)");
    $display("========================================\n");
    
    init_test_image();
    
    $display("[TB] Streaming 6x6 pixels...");
    
    // Stream all pixels
    for (int r = 0; r < IMG_HEIGHT; r = r + 1) begin
        for (int c = 0; c < IMG_WIDTH; c = c + 1) begin
            @(posedge iCLK);
            iDATA = test_img[r][c];
            iDVAL = 1;
            iX_Cont = c;
            iY_Cont = r;
        end
    end
    
    iDVAL = 0;
    $display("[TB] Input streaming complete. Waiting for outputs...\n");
    
    repeat (500) @(posedge iCLK); // Wait for outputs to stabilize
    
    $display("Testbench finished.");
    $stop();
end

always #5 iCLK = ~iCLK; 

endmodule
