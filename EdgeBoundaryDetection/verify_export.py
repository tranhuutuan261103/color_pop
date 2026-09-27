"""
Verify Export — So sánh chất lượng PyTorch vs TFLite
=====================================================
Script này chạy cùng 1 ảnh test qua cả PyTorch gốc và TFLite,
sau đó so sánh kết quả bằng nhiều metric:
- MAE (Mean Absolute Error)
- Max Error
- SSIM (Structural Similarity)
- Visual comparison (lưu ảnh)
"""

import torch
import numpy as np
from PIL import Image
import torchvision.transforms as transforms
import os
import sys
import cv2

# Ensure src can be imported
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from src.step03_model import HED


def load_pytorch_model(checkpoint_path="checkpoints/best_model.pth"):
    """Load model PyTorch gốc."""
    model = HED(pretrained_vgg=False)
    
    if os.path.exists(checkpoint_path):
        checkpoint = torch.load(checkpoint_path, map_location="cpu")
        if "model_state_dict" in checkpoint:
            model.load_state_dict(checkpoint["model_state_dict"])
        else:
            model.load_state_dict(checkpoint)
        print(f"✅ Loaded PyTorch model from {checkpoint_path}")
    else:
        print(f"⚠️  {checkpoint_path} not found, using random weights")
    
    model.eval()
    return model


def run_pytorch_inference(model, image_np, input_size=256):
    """
    Chạy inference PyTorch.
    image_np: numpy array HxWx3, RGB, uint8
    Returns: probability map (H, W), float32, [0-1]
    """
    img = Image.fromarray(image_np).convert('RGB')
    
    # Resize cho PyTorch (giống web app nếu cần)
    img_resized = img.resize((input_size, input_size), Image.BILINEAR)
    
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])
    
    img_tensor = transform(img_resized).unsqueeze(0)  # [1, 3, 256, 256]
    
    with torch.no_grad():
        outputs = model(img_tensor)
        fused_output = outputs[-1]
        prob = torch.sigmoid(fused_output)
        edge_map = prob[0, 0].cpu().numpy()
    
    return edge_map


def run_tflite_inference(tflite_path, image_np, input_size=256):
    """
    Chạy inference TFLite.
    image_np: numpy array HxWx3, RGB, uint8
    Returns: probability map (H, W), float32, [0-1]
    """
    try:
        import tensorflow as tf
    except ImportError:
        print("❌ Cần cài tensorflow: pip install tensorflow")
        return None
    
    interpreter = tf.lite.Interpreter(model_path=tflite_path)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print(f"  TFLite input: {input_details[0]['shape']} dtype={input_details[0]['dtype']}")
    print(f"  TFLite output: {output_details[0]['shape']} dtype={output_details[0]['dtype']}")
    
    # Chuẩn bị input giống hệt PyTorch
    img = Image.fromarray(image_np).convert('RGB')
    img_resized = img.resize((input_size, input_size), Image.BILINEAR)
    
    # Normalize theo ImageNet
    img_array = np.array(img_resized).astype(np.float32) / 255.0
    mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
    std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
    img_normalized = (img_array - mean) / std
    
    # Xác định format input của TFLite (NHWC hay NCHW)
    expected_shape = tuple(input_details[0]['shape'])
    
    if expected_shape[-1] == 3:
        # NHWC format: [1, H, W, 3]
        tflite_input = np.expand_dims(img_normalized, axis=0).astype(np.float32)
    elif expected_shape[1] == 3:
        # NCHW format: [1, 3, H, W]
        tflite_input = np.expand_dims(img_normalized.transpose(2, 0, 1), axis=0).astype(np.float32)
    else:
        print(f"  ⚠️ Unexpected input shape: {expected_shape}")
        # Try NHWC as default
        tflite_input = np.expand_dims(img_normalized, axis=0).astype(np.float32)
    
    print(f"  Prepared input shape: {tflite_input.shape}")
    
    interpreter.set_tensor(input_details[0]['index'], tflite_input)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]['index'])
    
    # Extract 2D probability map
    output_shape = output.shape
    if len(output_shape) == 4:
        if output_shape[-1] == 1:
            edge_map = output[0, :, :, 0]  # NHWC [1, H, W, 1]
        elif output_shape[1] == 1:
            edge_map = output[0, 0, :, :]  # NCHW [1, 1, H, W]
        else:
            edge_map = output[0, :, :, 0]
    elif len(output_shape) == 3:
        edge_map = output[0]
    else:
        edge_map = output.reshape(input_size, input_size)
    
    return edge_map


def compute_ssim(img1, img2):
    """Compute SSIM between two grayscale images."""
    # Simple SSIM implementation
    C1 = (0.01 * 255) ** 2
    C2 = (0.03 * 255) ** 2
    
    img1 = img1.astype(np.float64)
    img2 = img2.astype(np.float64)
    
    mu1 = cv2.GaussianBlur(img1, (11, 11), 1.5)
    mu2 = cv2.GaussianBlur(img2, (11, 11), 1.5)
    
    mu1_sq = mu1 ** 2
    mu2_sq = mu2 ** 2
    mu1_mu2 = mu1 * mu2
    
    sigma1_sq = cv2.GaussianBlur(img1 ** 2, (11, 11), 1.5) - mu1_sq
    sigma2_sq = cv2.GaussianBlur(img2 ** 2, (11, 11), 1.5) - mu2_sq
    sigma12 = cv2.GaussianBlur(img1 * img2, (11, 11), 1.5) - mu1_mu2
    
    ssim_map = ((2 * mu1_mu2 + C1) * (2 * sigma12 + C2)) / \
               ((mu1_sq + mu2_sq + C1) * (sigma1_sq + sigma2_sq + C2))
    
    return ssim_map.mean()


def compare_models(image_path, tflite_paths, checkpoint_path="checkpoints/best_model.pth",
                   output_dir="verification_results"):
    """
    So sánh PyTorch vs TFLite trên 1 ảnh.
    Lưu ảnh kết quả và in ra thống kê.
    """
    os.makedirs(output_dir, exist_ok=True)
    
    # Load ảnh
    image = cv2.imread(image_path)
    if image is None:
        print(f"❌ Không thể đọc ảnh: {image_path}")
        return
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    
    print(f"\n📷 Ảnh test: {image_path} ({image.shape[1]}x{image.shape[0]})")
    
    # Chạy PyTorch
    print("\n🔵 Chạy PyTorch inference...")
    model = load_pytorch_model(checkpoint_path)
    pytorch_output = run_pytorch_inference(model, image_rgb)
    
    pytorch_uint8 = (pytorch_output * 255).clip(0, 255).astype(np.uint8)
    pytorch_inverted = cv2.bitwise_not(pytorch_uint8)
    cv2.imwrite(os.path.join(output_dir, "pytorch_output.png"), pytorch_inverted)
    print(f"  Output range: [{pytorch_output.min():.4f}, {pytorch_output.max():.4f}]")
    
    # Chạy TFLite cho mỗi file
    for tflite_path in tflite_paths:
        if not os.path.exists(tflite_path):
            print(f"\n⚠️  {tflite_path} không tồn tại, bỏ qua")
            continue
        
        label = os.path.basename(tflite_path).replace('.tflite', '')
        print(f"\n🟢 Chạy TFLite inference: {label}...")
        
        tflite_output = run_tflite_inference(tflite_path, image_rgb)
        if tflite_output is None:
            continue
        
        tflite_uint8 = (tflite_output * 255).clip(0, 255).astype(np.uint8)
        tflite_inverted = cv2.bitwise_not(tflite_uint8)
        cv2.imwrite(os.path.join(output_dir, f"{label}_output.png"), tflite_inverted)
        
        # Metrics
        mae = np.mean(np.abs(pytorch_output.astype(np.float64) - tflite_output.astype(np.float64)))
        max_err = np.max(np.abs(pytorch_output.astype(np.float64) - tflite_output.astype(np.float64)))
        ssim = compute_ssim(pytorch_uint8, tflite_uint8)
        
        print(f"  Output range: [{tflite_output.min():.4f}, {tflite_output.max():.4f}]")
        print(f"  MAE:       {mae:.6f}")
        print(f"  Max Error: {max_err:.6f}")
        print(f"  SSIM:      {ssim:.6f}")
        
        status = "✅ TUYỆT VỜI" if mae < 0.01 else "⚠️ KHÁ TỐT" if mae < 0.05 else "❌ CẦN KIỂM TRA"
        print(f"  Đánh giá:  {status}")
        
        # Tạo ảnh so sánh side-by-side
        diff = np.abs(pytorch_uint8.astype(np.int16) - tflite_uint8.astype(np.int16)).astype(np.uint8)
        diff_colored = cv2.applyColorMap(diff * 5, cv2.COLORMAP_JET)  # Phóng đại 5x để dễ nhìn
        
        comparison = np.hstack([
            cv2.cvtColor(pytorch_inverted, cv2.COLOR_GRAY2BGR),
            cv2.cvtColor(tflite_inverted, cv2.COLOR_GRAY2BGR),
            diff_colored
        ])
        cv2.imwrite(os.path.join(output_dir, f"comparison_{label}.png"), comparison)
    
    print(f"\n📁 Kết quả lưu tại: {output_dir}/")


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Verify TFLite export quality")
    parser.add_argument("--img", type=str, default=None, help="Path to test image")
    parser.add_argument("--model", type=str, default="checkpoints/best_model.pth", help="PyTorch checkpoint path")
    parser.add_argument("--tflite", nargs="+", default=["hed_mobile_v2_fp32.tflite", "hed_mobile_v2_fp16.tflite"],
                        help="TFLite model paths to verify")
    parser.add_argument("--output-dir", type=str, default="verification_results", help="Output directory")
    
    args = parser.parse_args()
    
    if args.img is None:
        # Tạo ảnh test đơn giản nếu không có ảnh
        print("Tạo ảnh test tự động (hình vuông đen trên nền trắng)...")
        test_img = np.ones((256, 256, 3), dtype=np.uint8) * 255
        cv2.rectangle(test_img, (50, 50), (200, 200), (0, 0, 0), 8)
        cv2.circle(test_img, (128, 128), 60, (128, 128, 128), 5)
        test_path = "test_verify.png"
        cv2.imwrite(test_path, test_img)
        args.img = test_path
    
    compare_models(args.img, args.tflite, args.model, args.output_dir)
