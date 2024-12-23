module cnn_3filters #(
    parameter IMG_SIZE = 6,      // Image size (6x6x6)
    parameter FILT_SIZE = 3,     // Filter size (3x3x3)
    parameter NUM_FILTERS = 3    // Number of filters
)(
    input wire clk,
    input wire reset,
    output reg signed [15:0] pool_result[(IMG_SIZE-FILT_SIZE+1)/2*(IMG_SIZE-FILT_SIZE+1)/2*(IMG_SIZE-FILT_SIZE+1)/2*NUM_FILTERS-1:0],
	 output reg signed [15:0] conv_result[(IMG_SIZE-FILT_SIZE+1)*(IMG_SIZE-FILT_SIZE+1)*(IMG_SIZE-FILT_SIZE+1)*NUM_FILTERS-1:0], 
    output reg done
);

// Wire declarations
//wire signed [15:0] conv_result[(IMG_SIZE-FILT_SIZE+1)*(IMG_SIZE-FILT_SIZE+1)*(IMG_SIZE-FILT_SIZE+1)*NUM_FILTERS-1:0]; // Convolution output
wire conv_done;  // Convolution done flag
wire pool_done;  // Pooling done flag

// Instantiate the convolution module
cnn_3d_convolution #(
    .IMG_SIZE(IMG_SIZE),
    .FILT_SIZE(FILT_SIZE),
    .NUM_FILTERS(NUM_FILTERS)
) conv (
    .clk(clk),
    .reset(reset),
    .result(conv_result),
    .done(conv_done)
);

// Instantiate the max pooling module
cnn_3d_max_pooling #(
    .IMG_SIZE(IMG_SIZE - FILT_SIZE + 1), // Adjusted size after convolution
    .NUM_FILTERS(NUM_FILTERS)
) pool (
    .clk(clk),
    .reset(reset),
    .conv_result(conv_result),
    .pool_result(pool_result),
    .done(pool_done)
);

// Done flag logic
always_ff @(posedge clk or posedge reset) begin
    if (reset)
        done <= 0;
    else
        done <= conv_done && pool_done;
end


endmodule
