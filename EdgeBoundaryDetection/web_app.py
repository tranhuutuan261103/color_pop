import gradio as gr
import torch
import numpy as np
from PIL import Image
import torchvision.transforms as transforms
import os
import subprocess
import re

# ==========================================
# 1. TỰ ĐỘNG DỌN DẸP PORT BỊ KẸT (WINDOWS)
# ==========================================
def kill_process_on_port(port):
    try:
        # Find PID holding the port
        result = subprocess.run(f"netstat -ano | findstr :{port}", shell=True, capture_output=True, text=True)
        lines = result.stdout.strip().split('\n')
        for line in lines:
            if f":{port}" in line and "LISTENING" in line:
                parts = re.split(r'\s+', line.strip())
                pid = parts[-1]
                print(f"Cleaning up port {port} (PID: {pid})...")
                subprocess.run(f"taskkill /PID {pid} /F", shell=True, capture_output=True)
                print("Port released successfully!")
                break
    except Exception as e:
        print("Skipping port cleanup:", e)

# Release port 7860 before starting
kill_process_on_port(7860)

# ==========================================
# 2. KHỞI TẠO MÔ HÌNH HED
# ==========================================
from src.step03_model import HED

device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
model = HED(pretrained_vgg=False).to(device)

best_model_path = "./checkpoints/best_model.pth"
if os.path.exists(best_model_path):
    print(f"Loading weights from {best_model_path}")
    checkpoint = torch.load(best_model_path, map_location=device)
    model.load_state_dict(checkpoint['model_state_dict'])
else:
    print(f"WARNING: {best_model_path} not found. Using untrained model.")
model.eval()

# ==========================================
# 3. POST-PROCESSING: LÀM MƯỢT ĐƯỜNG VIỀN
# ==========================================
import cv2

def smooth_edges(edge_map, threshold=0.5, use_soft_edges=False, soft_edge_clarity=8.0,
                 gaussian_blur_size=0, morphology_size=0, anti_alias_sigma=0.0):
    """
    Pipeline làm mượt đường viền sau khi model dự đoán.
    
    Args:
        edge_map: numpy array (H, W) giá trị 0→1 (probability map từ sigmoid)
        threshold: ngưỡng để chuyển từ probability → binary (0.0 - 1.0)
        use_soft_edges: nếu True, dùng Sigmoid Contrast để tạo đường viền mượt mà sắc nét
        soft_edge_clarity: độ dốc của đường cong S (sigmoid steepness), càng cao càng rõ nét
        gaussian_blur_size: kích thước kernel Gaussian Blur (0 = tắt, lẻ: 3, 5, 7...)
        morphology_size: kích thước kernel morphology (0 = tắt, 2-5 thường dùng)
        anti_alias_sigma: sigma cho Gaussian Blur anti-alias cuối cùng (0 = tắt)
    
    Returns:
        result: numpy array (H, W) uint8, giá trị 0-255
    """
    
    if use_soft_edges:
        # ===== SIGMOID CONTRAST (Đường cong S) =====
        # 
        # Vấn đề: Probability map từ model có giá trị trung gian khắp nơi
        # (VD: nền = 0.05-0.15, viền mờ = 0.3, viền đậm = 0.7)
        # → Ảnh trông bị "sương mù" / đục / không trong.
        #
        # Giải pháp: Áp dụng hàm Sigmoid (đường cong S) để:
        #   - Đẩy các pixel nền (giá trị thấp) → 0 (trắng tinh)
        #   - Đẩy các pixel viền (giá trị cao) → 1 (đen tuyệt đối)
        #   - Giữ nguyên gradient mượt ở rìa viền (anti-alias tự nhiên)
        #   → Kết quả: viền sắc nét, nền sạch, nhưng rìa viền vẫn mềm mại
        #
        # Công thức: output = 1 / (1 + exp(-k * (x - midpoint)))
        #   k = soft_edge_clarity (độ dốc): cao = nét hơn, thấp = mềm hơn
        #   midpoint = threshold (điểm giữa đường cong S)
        
        # Bước 1: Auto-Levels - chuẩn hóa dải giá trị
        min_val = np.percentile(edge_map, 0.5)
        max_val = np.percentile(edge_map, 99.5)
        if max_val > min_val:
            edge_map = (edge_map - min_val) / (max_val - min_val)
        edge_map = np.clip(edge_map, 0, 1.0)
        
        # Bước 2: Sigmoid Contrast
        # k controls steepness: 1 = very soft, 8 = balanced, 20 = very sharp  
        k = soft_edge_clarity
        midpoint = threshold
        
        # Tránh overflow trong exp bằng cách clip argument
        sigmoid_arg = -k * (edge_map - midpoint)
        sigmoid_arg = np.clip(sigmoid_arg, -50, 50)
        result = 1.0 / (1.0 + np.exp(sigmoid_arg))
        
        result = (result * 255).astype(np.uint8)
        
        # Soft Edges KHÔNG áp dụng thêm anti-alias (sigmoid đã mượt sẵn)
    else:
        # ===== Gaussian Blur trước Threshold =====
        if gaussian_blur_size > 0:
            k = gaussian_blur_size if gaussian_blur_size % 2 == 1 else gaussian_blur_size + 1
            edge_map = cv2.GaussianBlur(edge_map, (k, k), sigmaX=0)
        
        # Hard threshold
        result = (edge_map > threshold).astype(np.uint8) * 255
        
        # ===== Morphological Operations =====
        if morphology_size > 0:
            kernel = cv2.getStructuringElement(
                cv2.MORPH_ELLIPSE, (morphology_size, morphology_size)
            )
            result = cv2.morphologyEx(result, cv2.MORPH_CLOSE, kernel)
            result = cv2.morphologyEx(result, cv2.MORPH_OPEN, kernel)
        
        # Anti-Alias cuối cùng (chỉ cho chế độ threshold)
        if anti_alias_sigma > 0:
            k_aa = int(anti_alias_sigma * 4) | 1
            k_aa = max(k_aa, 3)
            result = cv2.GaussianBlur(result, (k_aa, k_aa), sigmaX=anti_alias_sigma)
    
    return result

# ==========================================
# 4. HÀM DỰ ĐOÁN
# ==========================================
def predict_edge(input_image, invert_colors, threshold, use_soft_edges, soft_edge_clarity,
                 gaussian_blur_size, morphology_size, anti_alias_sigma):
    if input_image is None:
        return None
        
    img = Image.fromarray(input_image).convert('RGB')
    
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])
    
    img_tensor = transform(img).unsqueeze(0).to(device)
    
    with torch.no_grad():
        outputs = model(img_tensor)
        fused_output = outputs[-1]
        prob = torch.sigmoid(fused_output)
        edge_map = prob[0, 0].cpu().numpy()
    
    # Áp dụng pipeline làm mượt
    final_edge = smooth_edges(
        edge_map,
        threshold=threshold,
        use_soft_edges=use_soft_edges,
        soft_edge_clarity=soft_edge_clarity,
        gaussian_blur_size=int(gaussian_blur_size),
        morphology_size=int(morphology_size),
        anti_alias_sigma=anti_alias_sigma
    )
    
    if invert_colors:
        final_edge = cv2.bitwise_not(final_edge)
        
    return final_edge

# ==========================================
# 5. GIAO DIỆN WEB
# ==========================================
with gr.Blocks() as app:
    gr.Markdown("# 🎨 HED Edge Detection cho Ứng Dụng Tô Màu")
    gr.Markdown("Sử dụng mô hình HED để tách viền từ ảnh gốc. "
                "Điều chỉnh các thanh trượt để có đường viền **mượt mà và sắc nét**!")
    
    with gr.Row():
        # --- Cột trái: Input + Controls ---
        with gr.Column():
            input_img = gr.Image(label="📷 Ảnh Gốc (Original Image)")
            
            gr.Markdown("### ⚙️ Cài đặt cơ bản")
            invert_cb = gr.Checkbox(
                label="Đảo màu (Invert Colors) — Bật để nền trắng, viền đen",
                value=True
            )
            threshold_slider = gr.Slider(
                minimum=0.1, maximum=0.95, step=0.05, value=0.5,
                label="🎯 Ngưỡng (Threshold)",
                info="Điểm giữa để phân biệt viền/nền. Thấp = nhiều chi tiết, Cao = ít chi tiết"
            )
            
            gr.Markdown("### 🧹 Làm mượt đường viền")
            soft_edges_cb = gr.Checkbox(
                label="Dùng Soft Edges — Viền mượt + sắc nét (bỏ qua Gaussian/Morphology/Anti-Alias)",
                value=False
            )
            soft_edge_clarity_slider = gr.Slider(
                minimum=1.0, maximum=25.0, step=0.5, value=8.0,
                label="🔍 Độ trong (Clarity)",
                info="Thấp (1-4) = mềm mại. Trung bình (6-10) = cân bằng. Cao (12-25) = sắc nét, nền sạch"
            )
            
            gr.Markdown("### 🔧 Chế độ Threshold (khi tắt Soft Edges)")
            gaussian_slider = gr.Slider(
                minimum=0, maximum=15, step=2, value=3,
                label="🌫️ Gaussian Blur (trước threshold)",
                info="0 = Tắt. Giá trị lớn = mượt hơn, nhưng mất chi tiết nhỏ"
            )
            morphology_slider = gr.Slider(
                minimum=0, maximum=7, step=1, value=3,
                label="🔧 Morphology (lấp lỗ hổng + loại noise)",
                info="0 = Tắt. 2-3 = Nhẹ, 4-5 = Mạnh"
            )
            anti_alias_slider = gr.Slider(
                minimum=0.0, maximum=3.0, step=0.1, value=0.8,
                label="✨ Anti-Alias Sigma (blur nhẹ cuối cùng)",
                info="0 = Tắt. 0.5-1.0 = Nhẹ, 1.5-3.0 = Mạnh"
            )
            
            submit_btn = gr.Button("🚀 Tách Viền", variant="primary", size="lg")
            
        # --- Cột phải: Output ---
        with gr.Column():
            output_img = gr.Image(label="🖼️ Ảnh Viền (HED Prediction)", image_mode="L")
            
    submit_btn.click(
        fn=predict_edge,
        inputs=[input_img, invert_cb, threshold_slider, soft_edges_cb, soft_edge_clarity_slider,
                gaussian_slider, morphology_slider, anti_alias_slider],
        outputs=output_img
    )
    
    gr.Markdown("---")
    gr.Markdown("### 💡 Hướng dẫn sử dụng")
    gr.Markdown(
        "| Tham số | Tác dụng | Gợi ý |\n"
        "|---------|----------|-------|\n"
        "| **Threshold** | Điểm giữa phân biệt viền và nền | 0.3-0.5 cho ảnh phức tạp, 0.5-0.7 cho ảnh đơn giản |\n"
        "| **Soft Edges** | Bật chế độ Sigmoid Contrast — viền mượt + trong | **Nên bật** để có kết quả đẹp nhất |\n"
        "| **Clarity** | Độ sắc nét khi bật Soft Edges | 6-10 = cân bằng mượt/nét. 12-20 = rất sắc |\n"
        "| **Gaussian Blur** | Làm mượt trước threshold (chỉ khi tắt Soft Edges) | 3-5 |\n"
        "| **Morphology** | Lấp lỗ hổng + loại noise (chỉ khi tắt Soft Edges) | 2-3 |\n"
        "| **Anti-Alias** | Blur nhẹ cuối (chỉ khi tắt Soft Edges) | 0.5-1.0 |"
    )
    gr.Markdown("### So sánh với công nghệ cũ")
    gr.Markdown("Khác với Canny Edge (tìm tất cả chi tiết nhỏ lẻ, gây nhiễu), HED có khả năng học đa cấp độ (multi-scale) "
                "để tìm ra các đường nét ngữ nghĩa (semantic edges) của vật thể, vô cùng phù hợp cho app tô màu.")

if __name__ == "__main__":
    # Dùng 127.0.0.1 để bạn có thể bấm thẳng vào link được sinh ra
    app.launch(server_name="127.0.0.1", server_port=7860, share=False)
