module tb_cnn_3d;
    // Parameters
    localparam IMG_SIZE = 6;
    localparam FILT_SIZE = 3;
    localparam NUM_FILTERS = 3;
    localparam POOL_RESULT_SIZE = (IMG_SIZE - FILT_SIZE + 1) / 2;
    localparam VECTOR_SIZE = 24;  // Size of each row vector
    localparam NUM_ROWS = 8;      // Number of row vectors

    // Clock and reset signals
    reg clk;
    reg reset;
    localparam CONV_RESULT_SIZE = IMG_SIZE - FILT_SIZE + 1;
	 wire signed [15:0] conv_result[(IMG_SIZE-FILT_SIZE+1)*(IMG_SIZE-FILT_SIZE+1)*(IMG_SIZE-FILT_SIZE+1)*NUM_FILTERS-1:0];


    // Output signals from CNN module
    wire signed [15:0] pool_result[(POOL_RESULT_SIZE * POOL_RESULT_SIZE * POOL_RESULT_SIZE *NUM_FILTERS)-1:0];
    wire done;

    // Input matrix (4x24)
    reg signed [15:0] input_matrix[NUM_ROWS-1:0][VECTOR_SIZE-1:0]; // 4x24 input matrix

    // Result vector for storing multiplication output
    reg signed [31:0] result[NUM_ROWS-1:0]; // 4x1 result

    // File handle for reading input
    integer file, i, j;

    // Instantiate the CNN module
    cnn_3filters #(
        .IMG_SIZE(IMG_SIZE),
        .FILT_SIZE(FILT_SIZE),
        .NUM_FILTERS(NUM_FILTERS)
    ) uut (
        .clk(clk),
        .reset(reset),
		  .conv_result(conv_result),
        .pool_result(pool_result),
        .done(done)
    );

    // Clock generation
    always #5 clk = ~clk; // 100MHz clock

    // Initialize the input matrix and perform multiplication with maxpooling result
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;

        // Reset the system
        #10 reset = 0;
		  

        // Open the file containing input data
        file = $fopen("C:\\intelFPGA_lite\\18.1\\CNN_3D\\Cnn_3d_filters\\row1_24.txt", "r");
        if (file == 0) begin
            $display("Error: Could not open input_matrix.txt");
            $finish;
        end

        // Read the matrix data from the file
        for (i = 0; i < NUM_ROWS; i = i + 1) begin
            for (j = 0; j < VECTOR_SIZE; j = j + 1) begin
                $fscanf(file, "%d", input_matrix[i][j]);
            end
        end

        // Close the file after reading the data
        $fclose(file);

        // Wait for done signal from the CNN module
        wait(done);
		  
	
		$display("\nConvolution Output (conv_result):");
		for (integer f = 0; f < NUM_FILTERS; f = f + 1) begin
			 $display("Filter %0d:", f);
			 for (integer z = 0; z < CONV_RESULT_SIZE; z = z + 1) begin
				  $display("Depth %0d:", z);
				  for (integer i = 0; i < CONV_RESULT_SIZE; i = i + 1) begin
						for (integer j = 0; j < CONV_RESULT_SIZE; j = j + 1) begin
							 $write("%4d ", conv_result[f * CONV_RESULT_SIZE * CONV_RESULT_SIZE * CONV_RESULT_SIZE +
																z * CONV_RESULT_SIZE * CONV_RESULT_SIZE +
																i * CONV_RESULT_SIZE + j]);
						end
						$display("");
				  end
			 end
		end

		  
		  for (integer f = 0; f < NUM_FILTERS; f = f + 1) begin
            $display("Filter %0d:", f);
            
            // Depth 0
            $display("Depth 0:");
            for (integer i = 0; i < POOL_RESULT_SIZE; i = i + 1) begin
                for (integer j = 0; j < POOL_RESULT_SIZE; j = j + 1) begin
                    $write("%4d ", pool_result[f*POOL_RESULT_SIZE*POOL_RESULT_SIZE*POOL_RESULT_SIZE + 
                                               i*POOL_RESULT_SIZE + j]);
                end
                $display(""); // New line for each row
            end
            
            // Depth 1
            $display("Depth 1:");
            for (integer i = 0; i < POOL_RESULT_SIZE; i = i + 1) begin
                for (integer j = 0; j < POOL_RESULT_SIZE; j = j + 1) begin
                    $write("%4d ", pool_result[f*POOL_RESULT_SIZE*POOL_RESULT_SIZE*POOL_RESULT_SIZE + 
                                               POOL_RESULT_SIZE*POOL_RESULT_SIZE + 
                                               i*POOL_RESULT_SIZE + j]);
                end
                $display(""); // New line for each row
            end
        end



        // Display the maxpooling output (pool_result)
        $display("Maxpooling flatened output (pool_result):");
        for (integer f = 0; f < NUM_FILTERS; f = f + 1) begin
            
            for (integer depth = 0; depth < 2; depth = depth + 1) begin // Assuming depth is 2
                for (integer i = 0; i < POOL_RESULT_SIZE; i = i + 1) begin
                    for (integer j = 0; j < POOL_RESULT_SIZE; j = j + 1) begin
                        $display(" %0d", pool_result[f * POOL_RESULT_SIZE * POOL_RESULT_SIZE * POOL_RESULT_SIZE + 
                                        depth * POOL_RESULT_SIZE * POOL_RESULT_SIZE + 
                                        i * POOL_RESULT_SIZE + j]);
                    end
                end
            end
        end

        // Perform matrix multiplication with maxpooling result
        // Initialize result vector to 0
        for (integer i = 0; i < NUM_ROWS; i = i + 1) begin
            result[i] = 0;
        end

        // Perform dot product for each row with the pool_result
        for (integer f = 0; f < NUM_FILTERS; f = f + 1) begin
            for (integer depth = 0; depth < 2; depth = depth + 1) begin // Assuming depth is 2
                for (integer i = 0; i < POOL_RESULT_SIZE; i = i + 1) begin
                    for (integer j = 0; j < POOL_RESULT_SIZE; j = j + 1) begin
                        // Compute dot product for each row vector with the column matrix (maxpooling result)
                        for (integer r = 0; r < NUM_ROWS; r = r + 1) begin
                            result[r] = result[r] + input_matrix[r][i * POOL_RESULT_SIZE + j] * 
                                        pool_result[f * POOL_RESULT_SIZE * POOL_RESULT_SIZE * POOL_RESULT_SIZE + 
                                                    depth * POOL_RESULT_SIZE * POOL_RESULT_SIZE + 
                                                    i * POOL_RESULT_SIZE + j];
                        end
                    end
                end
            end
        end

        // Display the multiplication result
        $display("Matrix Multiplication Result (8x1 vector):");
        for (integer i = 0; i < NUM_ROWS; i = i + 1) begin
            $display(" %0d", result[i]);
        end

        $finish;
    end
endmodule
