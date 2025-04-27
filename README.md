# CiliaDetect

**Version 1.0**  
_A semi-automated tool for fast detection and quantification of cilia from microscopy image stacks (ND2 format)_

**Authors**:  
Pierre Gardères (pmgarderes@gmail.com)  
+ ChatGPT assistance (OpenAI)

---

## 🚀 Overview

**CiliaDetect** is a MATLAB-based tool that helps detect, segment, and quantify cilia across multi-channel microscopy datasets.  
It supports ND2 files (and downsampled stacks), semi-automated ROI detection, fluorescence quantification across multiple channels, and result export.

---

## 📋 Installation

1. Install **MATLAB** (tested on R2021b and newer).
2. Clone or download this repository:

   ```bash
   git clone https://github.com/yourusername/CiliaDetect.git
   ```

3. Add the repository and subfolders to your MATLAB path:

   ```matlab
   addpath(genpath('CiliaDetect'))
   ```

4. Ensure you have the basic MATLAB toolboxes (Image Processing Toolbox).

---

## 📦 How it Works

The main workflow is handled through a **single wrapper file**:  
▶️ **`Wrapper_Cilia_Process.m`**

Users simply **open** the script, **set a few parameters**, and **evaluate line-by-line** (with F9 or right-click → Evaluate Section).

---

## 💪 Usage Procedure

### 1. Prepare Downsampled Data (optional but recommended)

If you have many `.nd2` files, you can pre-convert them into lightweight `.mat` stacks:

```matlab
foldername = 'D:\Path\To\Your\Data';
DSfactor = 25;
batch_downsample_nd2_folder(foldername, DSfactor, true);
```

This saves computation time later.

---

### 2. Run the Main Wrapper

Edit and run **`Wrapper_Cilia_Process.m`**, which guides you through:

- **Selecting the file** to analyze (either `.nd2` or `.mat` reduced stack).
- **Adjusting parameters** for detection and quantification.
- **Launching the GUI** to detect cilia:
  - Spacebar to detect.
  - Arrow keys to navigate.
  - `u` to undo last detection.
- **Saving the ROIs** automatically.
- **Visualizing** the detected cilia and background masks.
- **Quantifying fluorescence** across all channels.
- **Saving results** into an Excel file (`.xlsx`) for further statistical analysis.

All steps are performed sequentially by evaluating blocks of code.

---

## 🖥️ Main Parameters (in Wrapper)

- **params.load_reduced**: 1 to load a reduced `.mat` file, 0 to process raw `.nd2`.
- **params.DSfactor**: Downsampling factor for Z-averaging (default: 25).
- **params.windowSize**: Size of the detection ROI window.
- **params.minArea** / **maxArea**: Minimum and maximum ROI areas.
- **params.minElongation**: Minimum elongation (for filtering shapes).
- **params.minThinness**: Minimum thinness (skeleton-based filter).
- **params.adaptiveSensitivity**: Adaptive threshold sensitivity (0.3-0.7).
- **params.backgroundSpread**: Dilation size for background calculation.
- **params.fluorescenceMode**: `'mean'` or `'sum'` (choose fluorescence computation mode).

---

## 🌟 Outputs

Each analyzed file will generate:

- `.mat` files with saved detected ROIs.
- An `.xlsx` file summarizing:
  - ROI fluorescence (corrected for background).
  - ROI areas and background areas.
  - Multi-channel quantifications.

Example output table:

| Cilia ID | Channel 1 Corrected | Channel 2 Corrected | Area | Background Area | ... |
|----------|---------------------|---------------------|------|------------------|-----|

---

## 📜 Example: Quick Start

```matlab
%% Batch prepare ND2 files
dsfactor = 25;
foldername = 'D:\Path\To\Your\Data';
batch_downsample_nd2_folder(foldername, dsfactor, true);

%% Process a File
filename = 'D:\Path\To\Your\Data\reduced_stack\example_reduced.mat';

% Set parameters
params.load_reduced = 1;
params.DSfactor = 25;
params.reload_previous_Detection = 0;
params.windowSize = 100;
params.minArea = 10;
params.maxArea = 1500;
params.minElongation = 2.0;
params.minThinness = 2.0;
params.adaptiveSensitivity = 0.4;
params.maxroiOverlap = 0.8;
params.backgroundSpread = 10;
params.fluorescenceMode = 'sum';

% Load stack and previous detections (if any)
addpath(genpath('.\'));
if params.load_reduced == 0
    [imgStack, metadata] = load_nd2_image_downsampled(filename, params);
else
    load(filename);
end
uniqueDetections = [];

% Launch GUI
view_nd2_with_cilia_gui(imgStack, params, uniqueDetections);

% Deduplicate and save
uniqueDetections = deduplicate_cilia_detections2(ciliaDetections, params.maxroiOverlap);
save_cilia_detections(filename, ciliaDetections, uniqueDetections);

% Visualize
visualize_cilia_masks(imgStack, uniqueDetections, params);

% Quantify and export
results = quantify_cilia_fluorescence2(imgStack, uniqueDetections, params);
resultsTable = struct2table(results);
outputFilename = fullfile([fileparts(filename), filesep, 'MatlabQuantif', filesep, baseName 'cilia_quantification_results.xlsx']);
writetable(resultsTable, outputFilename);
```

---

## 📷 Future Improvements

- Full 3D cilia detection across Z.
- Fully automated batch processing.
- Parallel computing acceleration.

---

## 🎨 Example GUI Screenshot

*(Add screenshot here showing detected cilia overlays in different colors)*

---

## 📝 License

MIT License or similar open-source license can be added.

---

