""" 1. Script chuyển đổi Mask thành Viền (Boundary)
File mask_to_boundary.py sẽ quét qua tất cả các file mask 
trong thư mục bạn chỉ định, tìm viền của các đối tượng 
(sử dụng thư viện opencv và hàm tìm kiếm findContours để cho 
độ chính xác cao đến từng pixel, cực kỳ phù hợp cho huấn luyện mô hình). 
Sau đó script sẽ vẽ viền bằng màu đen (0) lên nền trắng (255).

Cách sử dụng (chạy trong Terminal):
    python mask_to_boundary.py --input <đường_dẫn_tới_thư_mục_mask> --output <đường_dẫn_lưu_kết_quả> """

import cv2
import numpy as np
import os
import argparse
from pathlib import Path

def mask_to_boundary(mask_path, output_path):
    """
    Chuyển đổi một ảnh mask thành ảnh viền đen trên nền trắng.
    """
    # Đọc ảnh mask dưới dạng ảnh xám
    mask = cv2.imread(str(mask_path), cv2.IMREAD_GRAYSCALE)
    
    if mask is None:
        print(f"Không thể đọc ảnh: {mask_path}")
        return False
        
    # Tạo nền trắng cùng kích thước với mask
    result = np.ones_like(mask) * 255
    
    # Tìm viền của các đối tượng trong mask
    # Sử dụng findContours cho độ chính xác cao
    # Threshold để đảm bảo mask là nhị phân (nếu mask có nhiều class, có thể dùng cv2.Canny)
    _, binary = cv2.threshold(mask, 1, 255, cv2.THRESH_BINARY)
    
    contours, _ = cv2.findContours(binary, cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)
    
    # Vẽ viền màu đen (0) lên nền trắng (255)
    # thickness=1 để viền mỏng và chính xác nhất
    cv2.drawContours(result, contours, -1, 0, thickness=1)
    
    # Một cách khác để lấy viền chính xác từng pixel bên trong mask:
    # kernel = np.ones((3, 3), np.uint8)
    # erosion = cv2.erode(binary, kernel, iterations=1)
    # boundary = binary - erosion
    # result[boundary > 0] = 0
    
    # Lưu kết quả
    cv2.imwrite(str(output_path), result)
    return True

def process_directory(input_dir, output_dir):
    """
    Xử lý tất cả các file mask trong thư mục.
    """
    input_path = Path(input_dir)
    output_path = Path(output_dir)
    
    # Tạo thư mục đầu ra nếu chưa có
    output_path.mkdir(parents=True, exist_ok=True)
    
    # Các định dạng ảnh phổ biến
    valid_extensions = ['.png', '.jpg', '.jpeg', '.bmp', '.tif', '.tiff']
    
    processed_count = 0
    for file_path in input_path.rglob('*'):
        if file_path.suffix.lower() in valid_extensions:
            # Tạo đường dẫn đầu ra tương ứng
            rel_path = file_path.relative_to(input_path)
            out_file = output_path / rel_path
            
            # Tạo thư mục con nếu cần
            out_file.parent.mkdir(parents=True, exist_ok=True)
            
            if mask_to_boundary(file_path, out_file):
                processed_count += 1
                
    print(f"Đã xử lý xong {processed_count} ảnh và lưu tại: {output_dir}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Chuyển đổi Mask thành viền đen nền trắng.")
    parser.add_argument("--input", type=str, default="dataset/processed/BSDS500/train/masks", help="Thư mục chứa ảnh mask gốc")
    parser.add_argument("--output", type=str, default="dataset/processed/BSDS500/train/boundaries", help="Thư mục lưu kết quả")
    
    args = parser.parse_args()
    
    if os.path.exists(args.input):
        print(f"Bắt đầu chuyển đổi từ {args.input} sang {args.output}...")
        process_directory(args.input, args.output)
    else:
        print(f"Thư mục đầu vào {args.input} không tồn tại! Vui lòng kiểm tra lại.")
