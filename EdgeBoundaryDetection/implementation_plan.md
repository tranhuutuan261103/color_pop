# Goal Description

Refactor the Edge/Boundary Detection pipeline to solve the critical issues identified in the audit (extreme class imbalance causing 0% edge detection, broken multiprocessing on Windows, lack of metrics). Build a robust, scalable system that supports CPU training, checkpoint resuming, early stopping, and Google Colab deployment.

## User Review Required

> [!CAUTION]
> **Dataset Modifications:**
> The current dataloader uses `INTER_NEAREST` on soft-labels (0 to 1), which creates jagged boundaries. I plan to change the target resizing to use `INTER_LINEAR` to preserve soft edges, and apply dynamic thresholding during training or evaluation. Alternatively, we can binarize all ground truth masks at `threshold >= 127` during preprocessing. **For now, I will keep soft labels but fix the interpolation.**

> [!WARNING]
> **File Restructuring:**
> The original scripts use `importlib.util` to load files like `03_dataloader.py` and `04_model.py`. This breaks multiprocessing on Windows (`num_workers>0`). I will rename the files (removing the `0X_` prefixes) and create `__init__.py` files so they can be imported as proper Python modules (e.g., `from src.dataset.dataloader import get_dataloaders`).

## Open Questions

None at this moment. The requirements in the prompt are extremely detailed and cover almost all edge cases.

## Proposed Changes

### Configuration and Root
- Create `configs/baseline.yaml` to store hyperparameters cleanly.

### `src/dataset`
- Rename `03_dataloader.py` to `dataloader.py`.
- Add basic augmentations using `torchvision.transforms` (RandomHorizontalFlip, RandomVerticalFlip).
- Fix resizing interpolation.

### `src/models`
- Rename `04_model.py` to `unet.py`.

### `src/losses` (New)
- Create `losses.py`.
- Implement `WeightedBCEWithLogitsLoss` (with dynamic `pos_weight` based on batch statistics).
- Implement `DiceLoss`.
- Implement `BCEDiceLoss` as the primary advanced loss function to combat class imbalance.

### `src/metrics` (New)
- Create `metrics.py`.
- Implement Precision, Recall, F1-Score, and Dice Coefficient calculations specifically tailored for highly imbalanced edge maps.

### `src/training`
- Rename `05_train.py` to `train.py`.
- Implement `Argparse` for CLI arguments (`--device`, `--resume`, `--debug`).
- Implement the Checkpoint System (`best.pt`, `last.pt`, `epoch_{X}.pt`).
- Implement Early Stopping logic.
- Add metric evaluation (F1/Dice) on the validation set.

### `notebooks`
- Create `colab_training.ipynb` with step-by-step instructions for Google Drive mounting, dataset downloading, and training via GPU.

## Verification Plan

### Automated Tests
- Run an **Overfit Test** (as requested by User) using `--debug` mode on 5-10 images. The model must achieve an F1-score > 0.9 on these specific images to prove the loss and model can learn.

### Manual Verification
- Run a quick CPU-based training session (1-2 epochs) with the new `BCEDiceLoss`.
- Run inference and visualize the predicted probability maps to ensure the model actually outputs edges instead of blank background.
- Test the `--resume` feature by stopping training manually and resuming from `last.pt`.
