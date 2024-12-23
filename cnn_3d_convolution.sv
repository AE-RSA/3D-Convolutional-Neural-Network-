module cnn_3d_convolution #(
    parameter IMG_SIZE = 6,   // Image size (NxNxD)
    parameter FILT_SIZE = 3,  // Filter size (MxMxD)
    parameter NUM_FILTERS = 3 // Number of filters
)(
    input wire clk,           // Clock signal
    input wire reset,         // Reset signal
    output reg signed [15:0] result[(IMG_SIZE-FILT_SIZE+1)*(IMG_SIZE-FILT_SIZE+1)*(IMG_SIZE-FILT_SIZE+1)*NUM_FILTERS-1:0], // Flattened output
    output reg done           // Convolution done flag
);

// Local parameters
localparam RESULT_SIZE = IMG_SIZE - FILT_SIZE + 1;

// FSM states
localparam IDLE    = 3'd0;
localparam LOAD    = 3'd1;
localparam COMPUTE = 3'd2;
localparam STORE   = 3'd3;
localparam FINISH  = 3'd4;

// Image and filter memory (1D arrays for $readmemh compatibility)
reg signed [7:0] img [0:IMG_SIZE*IMG_SIZE*IMG_SIZE-1];
reg signed [7:0] filter [0:NUM_FILTERS*FILT_SIZE*FILT_SIZE*FILT_SIZE-1];

// Internal registers for FSM
reg [2:0] state, next_state;
reg signed [15:0] sum;
reg [2:0] img_row, img_col, img_depth;
reg [1:0] filt_row, filt_col, filt_depth;
reg [15:0] result_idx;
reg [1:0] filter_idx;

// Load image and filter data from files
initial begin
    $readmemh("C:\\intelFPGA_lite\\18.1\\CNN_3D\\Cnn_3d_filters\\input.txt", img);
    $readmemh("C:\\intelFPGA_lite\\18.1\\CNN_3D\\Cnn_3d_filters\\filter.txt", filter);
end

// Helper function to get 3D image value
function automatic signed [7:0] get_img_value(
    input [2:0] depth,
    input [2:0] row, 
    input [2:0] col
);
begin
    if (depth < IMG_SIZE && row < IMG_SIZE && col < IMG_SIZE)
        get_img_value = img[depth * IMG_SIZE * IMG_SIZE + row * IMG_SIZE + col];
    else
        get_img_value = 0;
end
endfunction

// Helper function to get 3D filter value
function automatic signed [7:0] get_filter_value(
    input [1:0] filter_idx_in,
    input [1:0] depth,
    input [1:0] row, 
    input [1:0] col
);
begin
    if (depth < FILT_SIZE && row < FILT_SIZE && col < FILT_SIZE)
        get_filter_value = filter[filter_idx_in * FILT_SIZE * FILT_SIZE * FILT_SIZE + 
                                  depth * FILT_SIZE * FILT_SIZE + 
                                  row * FILT_SIZE + 
                                  col];
    else
        get_filter_value = 0;
end
endfunction

// State transitions
always @(posedge clk or posedge reset) begin
    if (reset)
        state <= IDLE;
    else
        state <= next_state;
end

// Next state logic
always @(*) begin
    case (state)
        IDLE: next_state = !reset ? LOAD : IDLE;
        LOAD: next_state = COMPUTE;
        COMPUTE: begin
            if ((filt_row == FILT_SIZE-1) && 
                (filt_col == FILT_SIZE-1) && 
                (filt_depth == FILT_SIZE-1))
                next_state = STORE;
            else
                next_state = COMPUTE;
        end
        STORE: begin
            if ((img_row == RESULT_SIZE-1) && 
                (img_col == RESULT_SIZE-1) && 
                (img_depth == RESULT_SIZE-1) && 
                (filter_idx == NUM_FILTERS-1))
                next_state = FINISH;
            else
                next_state = LOAD;
        end
        FINISH: next_state = IDLE;
        default: next_state = IDLE;
    endcase
end

// Output computation and control logic
always @(posedge clk or posedge reset) begin
    if (reset) begin
        img_row <= 3'b0;
        img_col <= 3'b0;
        img_depth <= 3'b0;
        filt_row <= 2'b0;
        filt_col <= 2'b0;
        filt_depth <= 2'b0;
        sum <= 16'b0;
        result_idx <= 16'b0;
        done <= 1'b0;
        filter_idx <= 2'b0;
    end 
    else begin
        case (state)
            IDLE: begin
                done <= 1'b0;
                img_row <= 3'b0;
                img_col <= 3'b0;
                img_depth <= 3'b0;
                result_idx <= 16'b0;
                filter_idx <= 2'b0;
            end
            
            LOAD: sum <= 16'b0;
            
            COMPUTE: begin
                sum <= sum + 
                    get_img_value(img_depth + filt_depth, img_row + filt_row, img_col + filt_col) * 
                    get_filter_value(filter_idx, filt_depth, filt_row, filt_col);
                
                // Increment filter indices
                if (filt_col < FILT_SIZE - 1)
                    filt_col <= filt_col + 1'b1;
                else begin
                    filt_col <= 2'b0;
                    if (filt_row < FILT_SIZE - 1)
                        filt_row <= filt_row + 1'b1;
                    else begin
                        filt_row <= 2'b0;
                        if (filt_depth < FILT_SIZE - 1)
                            filt_depth <= filt_depth + 1'b1;
                        else
                            filt_depth <= 2'b0;
                    end
                end
            end
            
            STORE: begin
                result[filter_idx * RESULT_SIZE * RESULT_SIZE * RESULT_SIZE + 
                       img_depth * RESULT_SIZE * RESULT_SIZE + 
                       img_row * RESULT_SIZE + 
                       img_col] <= sum;
                
                if (img_col < RESULT_SIZE - 1)
                    img_col <= img_col + 1'b1;
                else begin
                    img_col <= 3'b0;
                    if (img_row < RESULT_SIZE - 1)
                        img_row <= img_row + 1'b1;
                    else begin
                        img_row <= 3'b0;
                        if (img_depth < RESULT_SIZE - 1)
                            img_depth <= img_depth + 1'b1;
                        else begin
                            img_depth <= 3'b0;
                            if (filter_idx < NUM_FILTERS - 1)
                                filter_idx <= filter_idx + 1'b1;
                        end
                    end
                end
            end
            
            FINISH: done <= 1'b1;
        endcase
    end
end

endmodule
