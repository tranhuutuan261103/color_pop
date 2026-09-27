import torch
import cv2
import numpy as np
import argparse
import os
import albumentations as A
from albumentations.pytorch import ToTensorV2
import sys

# Ensure src can be imported
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from src.step03_model import HED

def smooth_edges(edge_map, threshold=0.5, use_soft_edges=False, soft_edge_intensity=3.0,
                 gaussian_blur_size=0, morphology_size=0, anti_alias_sigma=0.0):
    """
    Pipeline làm mượt đường viền sau khi model dự đoán.
    
    Args:
        edge_map: numpy array (H, W) giá trị 0→1 (probability map từ sigmoid)
        threshold: ngưỡng để chuyển từ probability → binary (0.0 - 1.0)
        use_soft_edges: nếu True, dùng trực tiếp probability map (gradient mượt tự nhiên)
        soft_edge_intensity: hệ số để tính gamma correction (tăng độ đậm nét)
        gaussian_blur_size: kích thước kernel Gaussian Blur (0 = tắt, lẻ: 3, 5, 7...)
        morphology_size: kích thước kernel morphology (0 = tắt, 2-5 thường dùng)
        anti_alias_sigma: sigma cho Gaussian Blur anti-alias cuối cùng (0 = tắt)
    
    Returns:
        result: numpy array (H, W) uint8, giá trị 0-255
    """
    
    if use_soft_edges:
        min_val = np.min(edge_map)
        max_val = np.percentile(edge_map, 99.5)
        
        if max_val > min_val:
            edge_map = (edge_map - min_val) / (max_val - min_val)
        edge_map = np.clip(edge_map, 0, 1.0)
        
        gamma = 1.0 / (1.0 + (soft_edge_intensity - 1.0) * 0.25)
        enhanced_edge = np.power(edge_map, gamma)
        result = (enhanced_edge * 255).astype(np.uint8)
    else:
        # Gaussian Blur trước Threshold
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

def infer_wild_image(image_path, model_path, output_path, device='cpu',
                     threshold=0.5, soft_edges=False, soft_edge_intensity=3.0,
                     gaussian_blur=3, morphology=3, anti_alias=0.8):
    if not os.path.exists(image_path):
        print(f"Error: Image {image_path} not found.")
        return
        
    print(f"Loading model from {model_path}...")
    model = HED(pretrained_vgg=False) # Architecture only
    
    if os.path.exists(model_path):
        checkpoint = torch.load(model_path, map_location=device)
        model.load_state_dict(checkpoint['model_state_dict'])
        print("Model weights loaded successfully.")
    else:
        print(f"Warning: Checkpoint {model_path} not found! Using random weights for demonstration.")
        
    model.to(device)
    model.eval()
    
    # 1. Read and preprocess image
    image = cv2.imread(image_path)
    if image is None:
        print("Failed to read image.")
        return
        
    original_h, original_w = image.shape[:2]
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    
    # Validation transform (only normalize and to tensor)
    transform = A.Compose([
        A.Normalize(mean=(0.485, 0.456, 0.406), std=(0.229, 0.224, 0.225)),
        ToTensorV2()
    ])
    
    input_tensor = transform(image=image)['image'].unsqueeze(0).to(device)
    
    # 2. Inference
    print("Running inference...")
    with torch.no_grad():
        outputs = model(input_tensor)
        # Use fused output (the last one in the list)
        fused_output = outputs[-1]
        
        # Apply sigmoid to get probabilities (0 to 1)
        prob_map = torch.sigmoid(fused_output).squeeze().cpu().numpy()
        
    # 3. Post-process: Làm mượt đường viền
    print("Post-processing with smoothing pipeline...")
    print(f"  Threshold: {threshold}, Soft Edges: {soft_edges}, Intensity: {soft_edge_intensity}")
    print(f"  Gaussian Blur: {gaussian_blur}, Morphology: {morphology}")
    print(f"  Anti-Alias Sigma: {anti_alias}")
    
    edge_map = smooth_edges(
        prob_map,
        threshold=threshold,
        use_soft_edges=soft_edges,
        soft_edge_intensity=soft_edge_intensity,
        gaussian_blur_size=gaussian_blur,
        morphology_size=morphology,
        anti_alias_sigma=anti_alias
    )
    
    # Invert: edge=0 (black), background=255 (white) cho coloring app
    line_art = cv2.bitwise_not(edge_map)
    
    # 4. Save result
    cv2.imwrite(output_path, line_art)
    print(f"Success! Line art saved to: {output_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Test model on wild images with edge smoothing")
    parser.add_argument("--img", type=str, required=True, help="Path to input image")
    parser.add_argument("--model", type=str, default="checkpoints/best_model.pth", help="Path to trained model")
    parser.add_argument("--out", type=str, default="output_lineart.png", help="Path to save output")
    
    # Smoothing parameters
    parser.add_argument("--threshold", type=float, default=0.5, help="Edge threshold (0.1-0.95, default: 0.5)")
    parser.add_argument("--soft-edges", action="store_true", help="Use soft edges (gradient, no threshold)")
    parser.add_argument("--intensity", type=float, default=3.0, help="Soft edges intensity (1.0-10.0, default: 3.0)")
    parser.add_argument("--gaussian-blur", type=int, default=3, help="Gaussian blur kernel size before threshold (0=off, default: 3)")
    parser.add_argument("--morphology", type=int, default=3, help="Morphology kernel size (0=off, default: 3)")
    parser.add_argument("--anti-alias", type=float, default=0.8, help="Anti-alias sigma (0=off, default: 0.8)")
    
    args = parser.parse_args()
    
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    infer_wild_image(
        args.img, args.model, args.out, device=device,
        threshold=args.threshold, soft_edges=args.soft_edges,
        soft_edge_intensity=args.intensity,
        gaussian_blur=args.gaussian_blur, morphology=args.morphology,
        anti_alias=args.anti_alias
    )
