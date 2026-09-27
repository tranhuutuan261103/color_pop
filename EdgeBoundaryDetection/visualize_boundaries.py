""" 2. Script trực quan hóa (Visualization)
File visualize_boundaries.py sẽ lấy ngẫu nhiên các mẫu ảnh 
trong tập mask gốc và so sánh trực tiếp với kết quả ảnh nền 
trắng viền đen vừa sinh ra thông qua giao diện matplotlib.

Cách sử dụng (chạy trong Terminal):
    python visualize_boundaries.py --mask <đường_dẫn_tới_thư_mục_mask> --boundary <đường_dẫn_tới_thư_mục_kết_quả> --samples 5
(Tham số --samples 5 nghĩa là bạn muốn lấy ngẫu nhiên 5 ảnh để hiển thị. Mặc định là 3 ảnh).

Một số lưu ý quan trọng để huấn luyện mô hình tốt hơn:
- Script lấy viền đang được set thickness=1 để tạo ra viền nhỏ và sắc nét nhất ở cấp độ pixel. Độ chính xác này rất cần thiết cho các mô hình Segmentations hoặc Edge Detection.
- Viền (Boundary) sẽ có giá trị pixel là 0 (đen) và nền (Background) là 255 (trắng). """

import cv2
import matplotlib.pyplot as plt
import os
import argparse
import random
from pathlib import Path

def visualize_samples(mask_dir, boundary_dir, num_samples=5):
    """
    Trực quan hóa ngẫu nhiên một số mẫu để so sánh giữa Mask và Boundary.
    """
    mask_path = Path(mask_dir)
    boundary_path = Path(boundary_dir)
    
    # Lấy danh sách tất cả các ảnh mask
    valid_extensions = ['.png', '.jpg', '.jpeg', '.bmp', '.tif', '.tiff']
    mask_files = [f for f in mask_path.rglob('*') if f.suffix.lower() in valid_extensions]
    
    if not mask_files:
        print(f"Không tìm thấy ảnh mask nào trong {mask_dir}")
        return
        
    # Chọn ngẫu nhiên một số mẫu (nếu số lượng ít hơn num_samples thì lấy tất cả)
    sample_files = random.sample(mask_files, min(num_samples, len(mask_files)))
    
    fig, axes = plt.subplots(len(sample_files), 2, figsize=(10, 4 * len(sample_files)))
    
    # Đảm bảo axes là mảng 2 chiều kể cả khi chỉ có 1 sample
    if len(sample_files) == 1:
        axes = axes.reshape(1, 2)
        
    for i, mask_file in enumerate(sample_files):
        # Đường dẫn tương đối để tìm file boundary tương ứng
        rel_path = mask_file.relative_to(mask_path)
        boundary_file = boundary_path / rel_path
        
        # Đọc ảnh mask (RGB để hiển thị đẹp bằng matplotlib)
        img_mask = cv2.imread(str(mask_file))
        if img_mask is not None:
            img_mask = cv2.cvtColor(img_mask, cv2.COLOR_BGR2RGB)
            axes[i, 0].imshow(img_mask)
        axes[i, 0].set_title(f"Original Mask: {mask_file.name}")
        axes[i, 0].axis('off')
        
        # Đọc ảnh boundary
        if boundary_file.exists():
            img_boundary = cv2.imread(str(boundary_file), cv2.IMREAD_GRAYSCALE)
            axes[i, 1].imshow(img_boundary, cmap='gray', vmin=0, vmax=255)
            axes[i, 1].set_title(f"Extracted Boundary")
        else:
            axes[i, 1].text(0.5, 0.5, 'Not Found', horizontalalignment='center')
        axes[i, 1].axis('off')
        
    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Trực quan hóa kết quả viền (Boundary) từ Mask.")
    parser.add_argument("--mask", type=str, default="dataset/masks", help="Thư mục chứa ảnh mask gốc")
    parser.add_argument("--boundary", type=str, default="dataset/boundaries", help="Thư mục chứa kết quả viền đen nền trắng")
    parser.add_argument("--samples", type=int, default=3, help="Số lượng ảnh mẫu muốn hiển thị")
    
    args = parser.parse_args()
    
    if os.path.exists(args.mask) and os.path.exists(args.boundary):
        visualize_samples(args.mask, args.boundary, args.samples)
    else:
        print("Đường dẫn thư mục mask hoặc boundary không chính xác. Vui lòng kiểm tra lại.")
