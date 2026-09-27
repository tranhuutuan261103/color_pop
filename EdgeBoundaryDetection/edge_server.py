"""
Edge Detection Server — Flask API chạy PyTorch gốc
=====================================================
Server nhận ảnh từ mobile app, chạy tách viền bằng model HED 
trên PyTorch (FP32, GPU/CPU), trả về ảnh PNG đã xử lý.

Logic tách viền 100% giống web_app.py (Gradio) để đảm bảo 
kết quả server == kết quả web app.

Endpoints:
  POST /detect-edges    — Nhận ảnh, trả về ảnh PNG tách viền
  GET  /health          — Health check
  GET  /model-info      — Thông tin model

Usage:
  python edge_server.py
  → Server chạy tại http://0.0.0.0:5000

  Từ mobile (cùng WiFi):
  POST http://<IP_MÁY_TÍNH>:5000/detect-edges
  Body: multipart/form-data, field "image" = file ảnh
  Optional form fields:
    threshold (float, default 0.5)
    invert_colors (bool, default true)
    use_soft_edges (bool, default true)
    soft_edge_clarity (float, default 8.0)
    gaussian_blur_size (int, default 3)
    morphology_size (int, default 3)
    anti_alias_sigma (float, default 0.8)
"""

import os
import sys
import io
import time
import threading
import numpy as np
from PIL import Image, ImageOps
import cv2
import torch
import torchvision.transforms as transforms
from flask import Flask, request, jsonify, send_file

# Ensure src can be imported
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from src.step03_model import HED

# ==========================================
# KHỞI TẠO
# ==========================================
app = Flask(__name__)

# Device
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(f"🖥️  Device: {device}")

# Load model
model = None
inference_lock = threading.Lock()
MODEL_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "checkpoints", "best_model.pth")


def load_model():
    global model
    print(f"Loading model from {MODEL_PATH}...")
    model = HED(pretrained_vgg=False).to(device)
    
    if os.path.exists(MODEL_PATH):
        checkpoint = torch.load(MODEL_PATH, map_location=device)
        if 'model_state_dict' in checkpoint:
            model.load_state_dict(checkpoint['model_state_dict'])
        else:
            model.load_state_dict(checkpoint)
        print(f"✅ Model loaded successfully")
    else:
        print(f"⚠️  WARNING: {MODEL_PATH} not found! Using untrained model.")
    
    model.eval()


# ==========================================
# POST-PROCESSING — Giống hệt web_app.py
# ==========================================
def smooth_edges(edge_map, threshold=0.5, use_soft_edges=False, soft_edge_clarity=8.0,
                 gaussian_blur_size=0, morphology_size=0, anti_alias_sigma=0.0):
    """
    Pipeline làm mượt đường viền — PORT 1-1 từ web_app.py.
    """
    if use_soft_edges:
        # ===== SIGMOID CONTRAST (Đường cong S) =====
        # Bước 1: Auto-Levels
        min_val = np.percentile(edge_map, 0.5)
        max_val = np.percentile(edge_map, 99.5)
        if max_val > min_val:
            edge_map = (edge_map - min_val) / (max_val - min_val)
        edge_map = np.clip(edge_map, 0, 1.0)
        
        # Bước 2: Sigmoid Contrast
        k = soft_edge_clarity
        midpoint = threshold
        sigmoid_arg = -k * (edge_map - midpoint)
        sigmoid_arg = np.clip(sigmoid_arg, -50, 50)
        result = 1.0 / (1.0 + np.exp(sigmoid_arg))
        result = (result * 255).astype(np.uint8)
    else:
        # ===== Gaussian Blur trước Threshold =====
        if gaussian_blur_size > 0:
            k = gaussian_blur_size if gaussian_blur_size % 2 == 1 else gaussian_blur_size + 1
            edge_map = cv2.GaussianBlur(edge_map, (k, k), sigmaX=0)
        
        # Hard threshold
        result = (edge_map > threshold).astype(np.uint8) * 255
        
        # Morphological Operations
        if morphology_size > 0:
            kernel = cv2.getStructuringElement(
                cv2.MORPH_ELLIPSE, (morphology_size, morphology_size)
            )
            result = cv2.morphologyEx(result, cv2.MORPH_CLOSE, kernel)
            result = cv2.morphologyEx(result, cv2.MORPH_OPEN, kernel)
        
        # Anti-Alias cuối cùng
        if anti_alias_sigma > 0:
            k_aa = int(anti_alias_sigma * 4) | 1
            k_aa = max(k_aa, 3)
            result = cv2.GaussianBlur(result, (k_aa, k_aa), sigmaX=anti_alias_sigma)
    
    return result


# ==========================================
# INFERENCE — Giống hệt web_app.py
# ==========================================
def predict_edge(image_pil, invert_colors=True, threshold=0.5,
                 use_soft_edges=False, soft_edge_clarity=8.0,
                 gaussian_blur_size=3, morphology_size=3,
                 anti_alias_sigma=0.8):
    """
    Chạy inference và post-processing.
    
    QUAN TRỌNG: Logic giống 100% web_app.py
    - KHÔNG resize cưỡng bức (giữ nguyên kích thước gốc)
    - Normalize theo ImageNet
    - Dùng fused output + sigmoid
    """
    img = ImageOps.exif_transpose(image_pil).convert('RGB')
    
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
# API ENDPOINTS
# ==========================================
@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'model_loaded': model is not None,
        'device': str(device),
        'cuda_available': torch.cuda.is_available(),
    })


@app.route('/model-info', methods=['GET'])
def model_info():
    """Thông tin chi tiết về model."""
    if model is None:
        return jsonify({'error': 'Model not loaded'}), 503
    
    total_params = sum(p.numel() for p in model.parameters())
    return jsonify({
        'model': 'HED (Holistically-Nested Edge Detection)',
        'backbone': 'VGG16',
        'total_parameters': total_params,
        'device': str(device),
        'precision': 'FP32',
        'checkpoint': MODEL_PATH,
        'note': 'Chạy PyTorch gốc — chất lượng cao nhất, giống web app'
    })


@app.route('/detect-edges', methods=['POST'])
def detect_edges():
    """
    Endpoint tách viền.
    
    Request:
      - Method: POST
      - Content-Type: multipart/form-data
      - Fields:
        - image (required): File ảnh (JPEG, PNG, etc.)
        - threshold (optional, float, default 0.5)
        - invert_colors (optional, bool, default true)
        - use_soft_edges (optional, bool, default true)
        - soft_edge_clarity (optional, float, default 8.0)
        - gaussian_blur_size (optional, int, default 3)
        - morphology_size (optional, int, default 3)
        - anti_alias_sigma (optional, float, default 0.8)
    
    Response:
      - Content-Type: image/png
      - Body: PNG image của kết quả tách viền
    """
    if model is None:
        return jsonify({'error': 'Model not loaded'}), 503
    
    # Kiểm tra file ảnh
    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided. Use field name "image"'}), 400
    
    file = request.files['image']
    if file.filename == '':
        return jsonify({'error': 'Empty filename'}), 400
    
    # Đọc ảnh
    try:
        image_bytes = file.read()
        image_pil = Image.open(io.BytesIO(image_bytes))
    except Exception as e:
        return jsonify({'error': f'Failed to decode image: {str(e)}'}), 400
    
    # Đọc parameters
    def parse_bool(val, default=True):
        if val is None:
            return default
        if isinstance(val, bool):
            return val
        return val.lower() in ('true', '1', 'yes')
    
    threshold = float(request.form.get('threshold', 0.5))
    invert_colors = parse_bool(request.form.get('invert_colors'), True)
    use_soft_edges = parse_bool(request.form.get('use_soft_edges'), False)
    soft_edge_clarity = float(request.form.get('soft_edge_clarity', 8.0))
    gaussian_blur_size = int(request.form.get('gaussian_blur_size', 3))
    morphology_size = int(request.form.get('morphology_size', 3))
    anti_alias_sigma = float(request.form.get('anti_alias_sigma', 0.8))
    
    # Chạy inference
    start_time = time.time()
    
    # The model is shared by Flask requests; serialize inference so slider
    # requests cannot corrupt a shared CPU/GPU execution.
    with inference_lock:
        result = predict_edge(
            image_pil,
            invert_colors=invert_colors,
            threshold=threshold,
            use_soft_edges=use_soft_edges,
            soft_edge_clarity=soft_edge_clarity,
            gaussian_blur_size=gaussian_blur_size,
            morphology_size=morphology_size,
            anti_alias_sigma=anti_alias_sigma
        )
    
    elapsed_ms = (time.time() - start_time) * 1000
    print(f"⚡ Inference completed in {elapsed_ms:.0f}ms "
          f"(size: {image_pil.size[0]}x{image_pil.size[1]}, "
          f"soft_edges={use_soft_edges}, threshold={threshold})")
    
    # Encode kết quả thành PNG
    _, buffer = cv2.imencode('.png', result)
    
    return send_file(
        io.BytesIO(buffer.tobytes()),
        mimetype='image/png',
        as_attachment=False,
        download_name='edge_result.png'
    )


# ==========================================
# MAIN
# ==========================================
if __name__ == "__main__":
    import socket
    
    load_model()
    
    # Tìm IP LAN để mobile có thể kết nối
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
    except:
        local_ip = "127.0.0.1"
    
    port = 5000
    
    print("\n" + "=" * 60)
    print("🚀 Edge Detection Server")
    print("=" * 60)
    print(f"  Local:   http://127.0.0.1:{port}")
    print(f"  LAN:     http://{local_ip}:{port}")
    print(f"  Device:  {device}")
    print(f"  Model:   {MODEL_PATH}")
    print()
    print("📱 Từ app mobile, gửi ảnh tới:")
    print(f"  POST http://{local_ip}:{port}/detect-edges")
    print()
    print("🧪 Test nhanh bằng curl:")
    print(f'  curl -X POST -F "image=@test_image.jpg" http://127.0.0.1:{port}/detect-edges --output result.png')
    print("=" * 60)
    
    app.run(host='0.0.0.0', port=port, debug=False)
