# 3D Convolutional Neural Network

## Project Overview

This project implements a **3D Convolutional Neural Network (CNN)** designed for feature extraction and classification tasks. The primary goal is to process 3D input matrices through convolutional and max-pooling layers.

---

## Key Features

- **3D Convolutional Layer**: Processes 3D input matrices using configurable filters for feature extraction.
- **Max-Pooling Layer**: Reduces the size of the feature maps, enhancing computational efficiency.
- **Matrix Multiplication**: Performs classification by calculating the dot product of pooled outputs with an input matrix.
- **Simulation Support**: Includes a testbench for simulating the CNN pipeline with Verilog.

---

## Methodology

The system operates in three stages:

1. **3D Convolution**
   - A 6x6x6 input matrix is processed using a 3x3x3 filter, generating feature maps.
   - Convolution is implemented as a hardware-optimized pipeline.

2. **Max-Pooling**
   - Reduces the size of the feature map, retaining the maximum values from 2x2x2 submatrices.
   - Outputs a smaller, representative feature map.

3. **Dot Product Calculation**
   - The pooled output is used for classification by calculating its dot product with a 4x24 matrix read from an external file (`row1_24.txt`).

---

## Input and Output

### Input:

1. A 6x6x6 image matrix.
2. A 3x3x3 convolution filter.
3. An 8x24 matrix stored in a `.txt` file (e.g., `row1_24.txt`).

### Output:

1. Feature maps after 3D convolution.
2. Reduced feature maps after max-pooling.
3. Final classification results from the dot product operation.

---

## Modules

### 1. `cnn_3filters.sv`
   - Hierarchical module integrating 3D convolution and max-pooling operations.

### 2. `cnn_3d_convolution.sv`
   - Performs 3D convolution to extract feature maps.
   - Outputs the convolution results (`conv_result`).

### 3. `cnn_3d_max_pooling.sv`
   - Performs 3D max-pooling on the convolution results to reduce spatial dimensions.
   - Outputs the pooling results (`pool_result`).

### 4. `tb_cnn_3d.sv`
   - Testbench simulating the CNN module, initializing the system, reading input matrix data, and performing operations:
     - **Input Data Initialization**: Loads a matrix from an external file (`row1_24.txt`).
     - **Matrix Multiplication**: Calculates the dot product of the pooled results with the input matrix (`row1_24.txt`).
     - **Results Display**: Prints the convolution and pooling results, as well as the matrix multiplication output.

---

## Module Parameters

- **IMG_SIZE**: Defines the size of the input image matrix (default: 6).
- **FILT_SIZE**: Defines the size of the filter matrix (default: 3).
- **NUM_FILTERS**: Number of filters applied during convolution (default: 3).

---

## Input and Output Ports

### Inputs:
- **clk**: Clock signal for synchronous operation.
- **reset**: Resets the module to an initial state.

### Outputs:
- **pool_result**: Result of the max-pooling operation, a reduced-size feature map.
- **conv_result**: Intermediate convolution results.
- **done**: Indicates completion of both convolution and pooling operations.

---

## Implementation Details

### Instantiation of Submodules

1. **Convolution Module (`cnn_3d_convolution`)**:
   - Takes `IMG_SIZE`, `FILT_SIZE`, and `NUM_FILTERS` as parameters.
   - Outputs a feature map (`conv_result`) of size `(IMG_SIZE - FILT_SIZE + 1)³ * NUM_FILTERS`.
   - Sets the `conv_done` flag when the operation completes.

2. **Max-Pooling Module (`cnn_3d_max_pooling`)**:
   - Takes adjusted image size `(IMG_SIZE - FILT_SIZE + 1)` and `NUM_FILTERS`.
   - Outputs the reduced feature map (`pool_result`) after max-pooling.
   - Sets the `pool_done` flag when the operation completes.

### Done Flag Logic

- Combines `conv_done` and `pool_done` flags.
- Sets the `done` output to 1 only when both convolution and pooling operations complete.

### Behavior

#### Reset Behavior
- On reset, the `done` signal is cleared (0).

#### Sequential Processing
1. The convolution module (`cnn_3d_convolution`) processes the input matrix and sets the `conv_done` flag.
2. The max-pooling module (`cnn_3d_max_pooling`) processes the `conv_result` and sets the `pool_done` flag.
3. Once both flags are set, the `done` signal indicates completion.

---

## Results

1. **Input Image Matrix**: A 6x6x6 image matrix.
2. **Feature Map**: Extracted after applying the 3x3x3 convolution filter.
3. **Pooled Output**: Reduced representation after max-pooling.
4. **Dot Product Result**: Classification output (8x1) based on the dot product with the 8x24 matrix.

---

## How to Use

1. Clone the repository.
2. Compile the Verilog modules using your preferred toolchain (e.g., ModelSim, Xilinx Vivado).
3. Load the input matrix and filter matrix from the provided `.txt` files.
4. Simulate the pipeline using the testbench (`tb_cnn_3d.sv`).
5. View the results printed in the simulation log.

---
## Authors  
Sudeep Asundi,  
Nithyasree  
Trainees at Ramaiah Skill Academy
