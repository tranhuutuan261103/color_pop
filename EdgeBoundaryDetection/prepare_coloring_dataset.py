import os
import glob
import argparse
import scipy.io as sio
import numpy as np
import cv2
from pathlib import Path

def process_mat_to_thick_boundary(mat_path, output_path, thickness=3, invert=True):
    """
    Đọc file .mat, lấy viền, làm viền dày lên, khép kín các kẽ hở 
    và lưu thành ảnh .png.
    """
    try:
        mat_data = sio.loadmat(mat_path, simplify_cells=True)
        ground_truth = mat_data["groundTruth"]
        
        # Nếu chỉ có 1 annotator thì biến nó thành list để dễ xử lý
        if isinstance(ground_truth, dict):
            ground_truth = [ground_truth]
        elif isinstance(ground_truth, np.ndarray):
            ground_truth = ground_truth.tolist()
            
        # Gộp tất cả các viền từ các annotators
        combined_boundaries = None
        for i, annotator in enumerate(ground_truth):
            boundary = annotator["Boundaries"]
            if combined_boundaries is None:
                combined_boundaries = boundary
            else:
                combined_boundaries = np.logical_or(combined_boundaries, boundary)
                
        # Chuyển sang ảnh grayscale (0: nền, 255: viền)
        img_boundary = combined_boundaries.astype(np.uint8) * 255
        
        # 1. Dùng Morphological CLOSE để nối các nét đứt, khép kín các kẽ hở mảnh
        kernel_close = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
        closed_boundary = cv2.morphologyEx(img_boundary, cv2.MORPH_CLOSE, kernel_close)
        
        # 2. Dùng Dilation để làm nét dày lên theo yêu cầu (ngăn tràn màu khi Flood Fill)
        kernel_dilate = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (thickness, thickness))
        thick_boundary = cv2.dilate(closed_boundary, kernel_dilate, iterations=1)
        
        # 3. Đảo ngược màu: nền trắng (255), viền đen (0) để giống ảnh tô màu
        if invert:
            final_img = cv2.bitwise_not(thick_boundary)
        else:
            final_img = thick_boundary
            
        # Lưu kết quả
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        cv2.imwrite(output_path, final_img)
        return True
    
    except Exception as e:
        print(f"Lỗi khi xử lý file {mat_path}: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Phục hồi và tạo Dataset viền dày cho App tô màu.")
    parser.add_argument("--raw_dir", type=str, default="dataset/raw/BSDS500/ground_truth", help="Thư mục chứa file .mat gốc")
    parser.add_argument("--out_dir", type=str, default="dataset/processed/BSDS500", help="Thư mục lưu ảnh mask đã được xử lý")
    parser.add_argument("--thickness", type=int, default=3, help="Độ dày của viền (pixel). Mặc định là 3.")
    parser.add_argument("--format", type=str, default="black_edge", choices=["black_edge", "white_edge"], 
                        help="black_edge: Viền đen nền trắng. white_edge: Viền trắng nền đen.")
    
    args = parser.parse_args()
    
    invert = (args.format == "black_edge")
    splits = ["train", "test", "val"]
    
    total_processed = 0
    for split in splits:
        input_split_dir = os.path.join(args.raw_dir, split)
        output_split_dir = os.path.join(args.out_dir, split, "masks")
        
        if not os.path.exists(input_split_dir):
            print(f"Không tìm thấy thư mục {input_split_dir}. Bỏ qua.")
            continue
            
        mat_files = glob.glob(os.path.join(input_split_dir, "*.mat"))
        print(f"Đang xử lý {len(mat_files)} ảnh trong tập {split}...")
        
        for mat_file in mat_files:
            file_name = os.path.basename(mat_file).replace(".mat", ".png")
            out_file = os.path.join(output_split_dir, file_name)
            
            if process_mat_to_thick_boundary(mat_file, out_file, thickness=args.thickness, invert=invert):
                total_processed += 1
                
    print(f"Đã phục hồi và tạo thành công {total_processed} mask viền dày tại: {args.out_dir}")

if __name__ == "__main__":
    main()
