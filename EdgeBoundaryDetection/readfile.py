import scipy.io as sio
import matplotlib.pyplot as plt
from pathlib import Path
import numpy as np


# ============================================================
# 1. Chọn file .mat
# ============================================================

mat_path = Path("dataset/ground_truth/test/100007.mat")

print("Đang đọc:", mat_path)


# ============================================================
# 2. Load .mat
# ============================================================

mat_data = sio.loadmat(
    mat_path,
    simplify_cells=True
)


# ============================================================
# 3. Lấy groundTruth
# ============================================================

ground_truth = mat_data["groundTruth"]

print("\nThông tin groundTruth:")
print("Type:", type(ground_truth))
print("Shape:", getattr(ground_truth, "shape", None))


# ============================================================
# 4. Kiểm tra annotator
# ============================================================

print("\nThông tin annotator:")

if isinstance(ground_truth, np.ndarray):
    num_annotators = ground_truth.size
else:
    num_annotators = len(ground_truth)

print("Số annotator:", num_annotators)


# ============================================================
# 5. Hiển thị từng annotator
# ============================================================

fig, axes = plt.subplots(
    num_annotators,
    2,
    figsize=(12, 4 * num_annotators)
)

# Trường hợp chỉ có 1 annotator
if num_annotators == 1:
    axes = np.expand_dims(axes, axis=0)


for i in range(num_annotators):

    # --------------------------------------------------------
    # Lấy annotator
    # --------------------------------------------------------

    annotator = ground_truth[i]

    print(f"\n========== Annotator {i + 1} ==========")
    print("Type:", type(annotator))

    if isinstance(annotator, dict):
        print("Keys:", annotator.keys())


    # --------------------------------------------------------
    # Lấy Segmentation
    # --------------------------------------------------------

    segmentation = annotator["Segmentation"]

    # --------------------------------------------------------
    # Lấy Boundaries
    # --------------------------------------------------------

    boundaries = annotator["Boundaries"]


    # --------------------------------------------------------
    # Chuyển sang numpy array
    # --------------------------------------------------------

    segmentation = np.asarray(segmentation)
    boundaries = np.asarray(boundaries)


    print("Segmentation:")
    print("  Shape:", segmentation.shape)
    print("  Dtype:", segmentation.dtype)
    print("  Min:", segmentation.min())
    print("  Max:", segmentation.max())

    print("Boundaries:")
    print("  Shape:", boundaries.shape)
    print("  Dtype:", boundaries.dtype)
    print("  Min:", boundaries.min())
    print("  Max:", boundaries.max())


    # ========================================================
    # Hiển thị Segmentation
    # ========================================================

    axes[i, 0].imshow(
        segmentation,
        cmap="nipy_spectral"
    )

    axes[i, 0].set_title(
        f"Annotator {i + 1} - Segmentation"
    )

    axes[i, 0].axis("off")


    # ========================================================
    # Hiển thị Boundaries
    # ========================================================

    axes[i, 1].imshow(
        boundaries,
        cmap="gray"
    )

    axes[i, 1].set_title(
        f"Annotator {i + 1} - Boundaries"
    )

    axes[i, 1].axis("off")


# ============================================================
# 6. Tiêu đề
# ============================================================

fig.suptitle(
    f"BSDS500 Ground Truth - {mat_path.name}",
    fontsize=18
)

plt.tight_layout()

plt.show()