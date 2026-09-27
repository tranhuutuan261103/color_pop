# MODEL DEVELOPMENT REPORT: Edge/Boundary Detection

## Phase 1: Source Code Audit

### 1. Project Architecture

The current project architecture consists of the following components:

```text
PROJECT ARCHITECTURE
├── Dataset
│   ├── src/dataset/01_extract_masks.py (Extracts edge and segmentation masks from .mat files)
│   ├── src/dataset/02_verify_visualize.py (Verifies matched images and masks)
│   ├── src/dataset/03_dataloader.py (Custom PyTorch Dataset and DataLoader with resizing)
├── Preprocessing
│   ├── Minimal preprocessing in dataloader (Resize, ToTensor, Normalize)
├── Augmentation
│   ├── None. Only normalizations are applied.
├── Model
│   ├── src/models/04_model.py (A standard U-Net architecture)
├── Loss
│   ├── BCEWithLogitsLoss (Used in src/training/05_train.py)
├── Training
│   ├── src/training/05_train.py (Basic training loop saving the best model based on validation loss)
├── Validation
│   ├── Basic validation loop inside 05_train.py calculating BCE loss
├── Evaluation
│   ├── No evaluation metrics implemented (Missing Precision, Recall, F1, etc.)
├── Inference
│   ├── None. No inference script provided.
└── Visualization
    ├── Basic visualization in 02_verify_visualize.py (only for ground truth)
```

### 2. Audit Findings

> [!CAUTION]
> **Critical Issues (Can cause the model to learn completely wrong things)**
> 1. **Loss Function / Class Imbalance Mismatch**: The model uses `BCEWithLogitsLoss` without any class balancing (`pos_weight`). In edge detection, edges constitute a tiny fraction of pixels (usually < 2%). The model will trivially predict everything as background (0) to achieve a low loss. 
> 2. **Ground Truth Loading / Formatting**: `03_dataloader.py` scales the mask by dividing by `255.0` (`mask = mask.astype(np.float32) / 255.0`), resulting in continuous soft labels in [0, 1] because `01_extract_masks.py` averaged annotations from multiple annotators. Soft labels aren't strictly wrong, but combined with plain BCE, it complicates learning and usually requires a careful thresholding or different loss formulation for edge detection.
> 3. **Improper Target Resizing**: `03_dataloader.py` resizes masks using `cv2.INTER_NEAREST`. Because the masks are soft (due to averaging annotators), nearest neighbor interpolation destroys the soft gradients of edges and creates jagged, unnatural boundaries.

> [!WARNING]
> **Major Issues (Significantly reduces performance)**
> 1. **No Data Augmentations**: The training pipeline does not use any augmentations (e.g., flips, rotations, scaling), which will lead to severe overfitting, especially on small datasets like BSDS500.
> 2. **No Proper Evaluation Metrics**: The training loop relies entirely on validation loss. Validation BCE loss can decrease while the model simply gets better at predicting background. The pipeline completely lacks Edge-specific metrics (F1, Precision, Recall, ODS/OIS).
> 3. **Architecture Lacks Residuals/Pretraining**: A plain U-Net from scratch is hard to train for thin edges without massive data or pre-trained encoder backbones (like ResNet).

> [!TIP]
> **Minor Issues (Code quality and maintainability)**
> 1. **Hardcoded Configurations**: Hyperparameters (epochs, lr, batch size, device) are hardcoded in `05_train.py`.
> 2. **Lack of Checkpoint System**: While the "best model" is saved, there is no logic to resume training from a checkpoint, and no early stopping mechanism.
> 3. **Non-standard Imports**: The code uses `importlib.util.spec_from_file_location` to load modules starting with numbers, which is bad practice. Files should be renamed to proper python module names (e.g., `extract_masks.py`).
> 4. **Hardcoded CPU/GPU logic**: `device` is detected automatically but cannot be overridden easily via command line arguments for local CPU testing vs Colab GPU training.

---

## Phase 2 & 3: Dataset Audit & Visualization

### Dataset Statistics
- **Total Images**: 500
- **Splits**: 
  - Train: 200 images, 200 masks
  - Validation: 100 images, 100 masks
  - Test: 200 images, 200 masks
- **Image Size**: Variable
  - Min: 321x321
  - Max: 481x481
  - Mean: 430.6 x 371.4

### Ground Truth Pixel Analysis (Class Imbalance)
A script was run to analyze the distribution of pixels in the ground truth masks of the training set.

```text
Edge pixels per image:
  Mean: 9862.6
  Median: 9312.0
  Min: 1245
  Max: 20449

Overall Pixel Ratio (Mask > 0):
  Positive (Edge): 6.3876%
  Negative (Background): 93.6124%

Overall Pixel Ratio (Mask >= 127):
  Positive (Edge): 0.7267%
  Negative (Background): 99.2733%
```

> [!IMPORTANT]
> **Class Imbalance Confirmed**: As we hypothesized in Phase 1, the dataset suffers from extreme class imbalance. If we consider any annotator's mark (mask > 0), only **~6.3%** of the pixels are edges. If we only consider strong consensus edges (mask >= 127), a mere **0.7%** of the pixels are edges. This is why standard BCE Loss fails completely; the model simply predicts background everywhere and achieves 99.3% accuracy and low BCE loss.

### Visualizations

Here are visual representations of the dataset samples and their corresponding boundaries. Note the soft (gray) edges in the Ground Truth due to annotator averaging.

![Sample 0](C:/Users/pc/.gemini/antigravity-ide/brain/2a0a4360-1e53-473c-a609-87e3624bf254/sample_0.png)

![Sample 1](C:/Users/pc/.gemini/antigravity-ide/brain/2a0a4360-1e53-473c-a609-87e3624bf254/sample_1.png)

![Sample 2](C:/Users/pc/.gemini/antigravity-ide/brain/2a0a4360-1e53-473c-a609-87e3624bf254/sample_2.png)

---

## Phase 4: Ground Truth Analysis

### Thin Edge Problem
As analyzed in Phase 2 and 3, edges occupy only **~6.3%** of all pixels (and only **0.7%** if thresholded strictly). This extreme class imbalance means that BCE loss will naturally push the model to predict background everywhere. Since the model gets 99.3% accuracy just by ignoring edges entirely, it is heavily biased towards `Type H: Model predicts background`.

In the Ground Truth dataset, since annotations are averaged from multiple people:
- Edges are soft (0 to 1).
- Edges can be thick where annotators disagree (creating a blur) or thin where they agree.
- A standard BCE loss without weighting or edge-aware formulation will treat soft edges as "low confidence" regions and suppress them to 0.

## Phase 5: U-Net Audit

The current model (`src/models/04_model.py`) is a standard U-Net:
- **Input**: 3 channels (RGB)
- **Output**: 1 channel (Logits for BCEWithLogitsLoss)
- **Architecture**: Standard Conv2d without residuals.
- **Normalization**: BatchNorm2d.

### Issues Identified:
1. The use of standard BCE loss directly with `BCEWithLogitsLoss` on soft-labels in a heavily imbalanced dataset.
2. The dataset loader scales labels to `[0, 1]`, and `BCEWithLogitsLoss` assumes the target is a probability, which is mathematically fine, but the imbalance overwhelms it.
3. No pre-trained backbone. Edge detection from scratch requires long training or careful initialization because low-level edges are hard to synthesize without ImageNet features.
4. The mask resizing with `INTER_NEAREST` in `03_dataloader.py` ruins the soft labels and creates artifacts.
5. In `05_train.py`, the code uses `num_workers=2` for the DataLoader but the module is dynamically loaded using `importlib.util`. This causes multiprocessing to crash entirely on Windows environments out-of-the-box.

## Phase 6: Model Inference & Debugging

We ran inference using the saved `best_unet_model.pth` on the validation set. 

> [!CAUTION]
> **Type H Error (Model Predicts Background)**: The inference results show that the model outputs a probability map that is almost entirely zero (background) everywhere. It completely fails to detect any edges. It learned that the safest prediction is "no edge" due to the extreme class imbalance and standard BCE loss.

### Inference Samples

Here are the results of the U-Net inference on the validation set. Notice how the Probability Map and the Prediction are blank (predicting all background).

````carousel
![Inference Sample 0](C:/Users/pc/.gemini/antigravity-ide/brain/2a0a4360-1e53-473c-a609-87e3624bf254/val_sample_0.png)
<!-- slide -->
![Inference Sample 1](C:/Users/pc/.gemini/antigravity-ide/brain/2a0a4360-1e53-473c-a609-87e3624bf254/val_sample_1.png)
<!-- slide -->
![Inference Sample 2](C:/Users/pc/.gemini/antigravity-ide/brain/2a0a4360-1e53-473c-a609-87e3624bf254/val_sample_2.png)
<!-- slide -->
![Inference Sample 3](C:/Users/pc/.gemini/antigravity-ide/brain/2a0a4360-1e53-473c-a609-87e3624bf254/val_sample_3.png)
<!-- slide -->
![Inference Sample 4](C:/Users/pc/.gemini/antigravity-ide/brain/2a0a4360-1e53-473c-a609-87e3624bf254/val_sample_4.png)
````

---
