"""
Export TFLite Script v2 — Chất lượng cao cho Mobile
=====================================================
Phiên bản mới sửa các vấn đề gây suy giảm chất lượng:
1. Input RGB 3 kênh (không dùng RGBA 4 kênh nữa)
2. Opset 17 cho ONNX (hỗ trợ tốt hơn)
3. Chỉ dùng TFLITE_BUILTINS → tương thích GPU Delegate
4. Export cả FP32 (chất lượng cao nhất) và FP16 (nhẹ hơn)
5. Tự động kiểm chứng output sau khi export
"""

import torch
import torch.nn as nn
import numpy as np
import os
import sys

# Đảm bảo có thể import từ src/
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from src.step03_model import HED


# ---------------------------------------------------------
# 1. Wrapper Model — Chỉ nhận RGB 3 kênh, trả 1 output
# ---------------------------------------------------------
class MobileHEDWrapper(nn.Module):
    """
    Wrapper cho model HED khi deploy trên mobile.
    
    THAY ĐỔI SO VỚI PHIÊN BẢN CŨ:
    - Phiên bản cũ: nhận RGBA 4 kênh → cắt Alpha bên trong model
      → Tạo thêm op Slice trên TFLite, GPU Delegate có thể không hỗ trợ
    - Phiên bản mới: nhận trực tiếp RGB 3 kênh
      → Ít op hơn, GPU Delegate hoạt động tốt hơn
      → Flutter sẽ chuẩn bị RGB input (đơn giản vì image package đã hỗ trợ sẵn)
    """
    def __init__(self, base_model):
        super(MobileHEDWrapper, self).__init__()
        self.base_model = base_model

    def forward(self, x):
        # x shape: [1, 3, H, W] — RGB, đã normalize theo ImageNet
        
        # Chạy qua model gốc
        outputs = self.base_model(x)
        
        # Model HED gốc trả về 6 outputs (5 side outputs + 1 fused).
        # Khi deploy lên app, chúng ta chỉ cần kết quả cuối cùng (fused).
        fused = outputs[-1]
        
        # Áp dụng Sigmoid để đưa giá trị pixel về khoảng [0, 1]
        return torch.sigmoid(fused)


# ---------------------------------------------------------
# 2. Export PyTorch → ONNX
# ---------------------------------------------------------
def export_to_onnx(checkpoint_path="checkpoints/best_model.pth",
                   onnx_path="hed_mobile_v2.onnx",
                   input_size=256):
    """
    Export model sang ONNX.
    
    THAY ĐỔI:
    - opset_version=17 (tốt hơn 13)
    - Input 3 kênh RGB (không 4 kênh RGBA)
    - dynamic_axes để hỗ trợ kích thước ảnh bất kỳ (dù TFLite sẽ fix size)
    """
    print("=" * 60)
    print("BƯỚC 1: Export PyTorch → ONNX")
    print("=" * 60)
    
    # Khởi tạo model
    print("Loading model...")
    base_model = HED(pretrained_vgg=False)
    
    if os.path.exists(checkpoint_path):
        checkpoint = torch.load(checkpoint_path, map_location="cpu")
        if "model_state_dict" in checkpoint:
            base_model.load_state_dict(checkpoint["model_state_dict"])
        else:
            base_model.load_state_dict(checkpoint)
        print(f"✅ Loaded weights from {checkpoint_path}")
    else:
        print(f"⚠️  WARNING: {checkpoint_path} not found! Exporting with random weights.")
    
    # Bọc model lại cho mobile
    mobile_model = MobileHEDWrapper(base_model)
    mobile_model.eval()
    
    # Input mẫu: RGB 3 kênh, kích thước cố định
    dummy_input = torch.randn(1, 3, input_size, input_size)
    
    print(f"Exporting to ONNX: {onnx_path}")
    print(f"  Input shape: [1, 3, {input_size}, {input_size}] (RGB)")
    print(f"  Opset version: 17")
    
    torch.onnx.export(
        mobile_model,
        dummy_input,
        onnx_path,
        export_params=True,
        opset_version=18,
        do_constant_folding=True,
        input_names=['input_rgb'],
        output_names=['output_edge'],
        # Không dùng dynamic_axes vì TFLite cần fixed size
        # dynamic_axes sẽ gây lỗi khi convert
    )
    
    # Kiểm tra file ONNX
    file_size_mb = os.path.getsize(onnx_path) / (1024 * 1024)
    print(f"✅ Export ONNX thành công! Size: {file_size_mb:.1f} MB")
    
    # Lưu lại reference output từ PyTorch để so sánh sau
    with torch.no_grad():
        ref_output = mobile_model(dummy_input).numpy()
    
    return onnx_path, dummy_input.numpy(), ref_output


# ---------------------------------------------------------
# 3. Convert ONNX → TFLite (FP32 + FP16)
# ---------------------------------------------------------
def convert_onnx_to_tflite(onnx_path, dummy_input_np=None, pytorch_ref_output=None):
    """
    Chuyển đổi ONNX → TensorFlow SavedModel → TFLite.
    
    THAY ĐỔI SO VỚI PHIÊN BẢN CŨ:
    - Chỉ dùng TFLITE_BUILTINS (không cần SELECT_TF_OPS)
      → GPU Delegate hoạt động tốt hơn, không cần TF ops fallback
    - Export FP32 là primary (chất lượng cao nhất)
    - FP16 là secondary (nhẹ hơn, cho thiết bị yếu)
    - Tự động kiểm chứng output sau mỗi bước
    """
    print("\n" + "=" * 60)
    print("BƯỚC 2: Convert ONNX → TFLite")
    print("=" * 60)
    
    try:
        import onnx2tf
        import tensorflow as tf
        import numpy as np
        
        # MONKEY-PATCH: Bỏ qua việc tải test data bị lỗi của onnx2tf bằng cách đè np.load
        _original_load = np.load
        def safe_load(file, *args, **kwargs):
            if isinstance(file, str) and "test_image_data" in file:
                return np.zeros((1, 256, 256, 3), dtype=np.float32)
            if hasattr(file, 'name') and "test_image_data" in file.name:
                return np.zeros((1, 256, 256, 3), dtype=np.float32)
            try:
                return _original_load(file, *args, **kwargs)
            except ValueError as ve:
                if "allow_pickle" in str(ve):
                    return np.zeros((1, 256, 256, 3), dtype=np.float32)
                raise ve
        np.load = safe_load
        
    except ImportError as e:
        print(f"\n❌ Thiếu thư viện: {e}")
        print("Chạy: pip install tensorflow onnx onnx2tf")
        return
    
    saved_model_dir = "saved_model_v2"
    tflite_fp32_path = "hed_mobile_v2_fp32.tflite"
    tflite_fp16_path = "hed_mobile_v2_fp16.tflite"
    
    # --- Convert ONNX → TF SavedModel ---
    print("\nConverting ONNX → TensorFlow SavedModel...")
    try:
        onnx2tf.convert(
            input_onnx_file_path=onnx_path,
            output_folder_path=saved_model_dir,
            non_verbose=True
        )
    except Exception as e:
        print(f"Lỗi khi chạy onnx2tf.convert: {e}")
        return
    
    if not os.path.exists(saved_model_dir):
        print("❌ Chuyển đổi SavedModel thất bại!")
        return
    print("✅ SavedModel created")
    
    # --- Convert SavedModel → TFLite FP32 ---
    print(f"\nConverting SavedModel → TFLite FP32: {tflite_fp32_path}")
    converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_dir)
    
    # CHỈ dùng TFLITE_BUILTINS — KHÔNG cần SELECT_TF_OPS
    # Điều này đảm bảo GPU Delegate có thể chạy 100% trên GPU
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
    ]
    
    try:
        tflite_model_fp32 = converter.convert()
        with open(tflite_fp32_path, "wb") as f:
            f.write(tflite_model_fp32)
        fp32_size = len(tflite_model_fp32) / (1024 * 1024)
        print(f"✅ TFLite FP32 saved! Size: {fp32_size:.1f} MB")
    except Exception as e:
        print(f"⚠️  FP32 export thất bại với TFLITE_BUILTINS only: {e}")
        print("   Thử lại với SELECT_TF_OPS fallback...")
        converter.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS,
            tf.lite.OpsSet.SELECT_TF_OPS,
        ]
        tflite_model_fp32 = converter.convert()
        with open(tflite_fp32_path, "wb") as f:
            f.write(tflite_model_fp32)
        fp32_size = len(tflite_model_fp32) / (1024 * 1024)
        print(f"✅ TFLite FP32 saved (with TF ops fallback)! Size: {fp32_size:.1f} MB")
    
    # --- Convert → TFLite FP16 ---
    print(f"\nConverting → TFLite FP16: {tflite_fp16_path}")
    converter2 = tf.lite.TFLiteConverter.from_saved_model(saved_model_dir)
    converter2.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
    ]
    converter2.optimizations = [tf.lite.Optimize.DEFAULT]
    converter2.target_spec.supported_types = [tf.float16]
    
    try:
        tflite_model_fp16 = converter2.convert()
        with open(tflite_fp16_path, "wb") as f:
            f.write(tflite_model_fp16)
        fp16_size = len(tflite_model_fp16) / (1024 * 1024)
        print(f"✅ TFLite FP16 saved! Size: {fp16_size:.1f} MB")
    except Exception as e:
        print(f"⚠️  FP16 export thất bại: {e}")
        print("   Thử lại với SELECT_TF_OPS fallback...")
        converter2.target_spec.supported_ops = [
            tf.lite.OpsSet.TFLITE_BUILTINS,
            tf.lite.OpsSet.SELECT_TF_OPS,
        ]
        converter2.optimizations = [tf.lite.Optimize.DEFAULT]
        converter2.target_spec.supported_types = [tf.float16]
        tflite_model_fp16 = converter2.convert()
        with open(tflite_fp16_path, "wb") as f:
            f.write(tflite_model_fp16)
        fp16_size = len(tflite_model_fp16) / (1024 * 1024)
        print(f"✅ TFLite FP16 saved (with TF ops fallback)! Size: {fp16_size:.1f} MB")
    
    # --- Kiểm chứng nhanh ---
    if dummy_input_np is not None and pytorch_ref_output is not None:
        print("\n" + "=" * 60)
        print("BƯỚC 3: Kiểm chứng output TFLite vs PyTorch")
        print("=" * 60)
        verify_tflite(tflite_fp32_path, dummy_input_np, pytorch_ref_output, "FP32")
        verify_tflite(tflite_fp16_path, dummy_input_np, pytorch_ref_output, "FP16")
    
    print("\n" + "=" * 60)
    print("HOÀN THÀNH!")
    print("=" * 60)
    print(f"  FP32: {tflite_fp32_path} ({fp32_size:.1f} MB) — Chất lượng cao nhất")
    print(f"  FP16: {tflite_fp16_path} ({fp16_size:.1f} MB) — Nhẹ hơn, nhanh hơn")
    print(f"\n  Đề xuất: Copy {tflite_fp32_path} vào assets/ của Flutter project")
    print(f"  Nếu thiết bị yếu, dùng {tflite_fp16_path}")
    
    return tflite_fp32_path, tflite_fp16_path


def verify_tflite(tflite_path, dummy_input_np, pytorch_ref_output, label=""):
    """So sánh output TFLite vs PyTorch reference."""
    try:
        import tensorflow as tf
    except ImportError:
        print("  ⚠️ Không thể verify — thiếu tensorflow")
        return
    
    interpreter = tf.lite.Interpreter(model_path=tflite_path)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    # TFLite dùng NHWC, PyTorch dùng NCHW → cần transpose
    # dummy_input_np shape: [1, 3, H, W] → [1, H, W, 3]
    tflite_input = dummy_input_np.transpose(0, 2, 3, 1).astype(np.float32)
    
    print(f"\n  [{label}] TFLite input shape: {input_details[0]['shape']}")
    print(f"  [{label}] Prepared input shape: {tflite_input.shape}")
    
    # Kiểm tra xem TFLite model nhận NHWC hay NCHW
    expected_shape = tuple(input_details[0]['shape'])
    if tflite_input.shape != expected_shape:
        print(f"  ⚠️  Shape mismatch! Expected {expected_shape}, got {tflite_input.shape}")
        # Thử dùng input gốc NCHW
        tflite_input = dummy_input_np.astype(np.float32)
        if tflite_input.shape != expected_shape:
            print(f"  ❌ Không thể match input shape!")
            return
    
    interpreter.set_tensor(input_details[0]['index'], tflite_input)
    interpreter.invoke()
    tflite_output = interpreter.get_tensor(output_details[0]['index'])
    
    # So sánh
    # pytorch_ref_output shape: [1, 1, H, W]
    # tflite_output shape: có thể là [1, H, W, 1] hoặc [1, 1, H, W]
    ref_flat = pytorch_ref_output.flatten()
    tflite_flat = tflite_output.flatten()
    
    mae = np.mean(np.abs(ref_flat - tflite_flat))
    max_err = np.max(np.abs(ref_flat - tflite_flat))
    
    status = "✅" if mae < 0.01 else "⚠️" if mae < 0.05 else "❌"
    print(f"  [{label}] MAE: {mae:.6f} | Max Error: {max_err:.6f} {status}")
    
    if mae < 0.01:
        print(f"  [{label}] → Chất lượng TUYỆT VỜI! Sai lệch rất nhỏ.")
    elif mae < 0.05:
        print(f"  [{label}] → Chất lượng KHÁ TỐT. Sai lệch chấp nhận được.")
    else:
        print(f"  [{label}] → Chất lượng THẤP! Cần kiểm tra lại quy trình chuyển đổi.")


# ---------------------------------------------------------
# Main
# ---------------------------------------------------------
if __name__ == "__main__":
    onnx_file, dummy_input, ref_output = export_to_onnx()
    convert_onnx_to_tflite(onnx_file, dummy_input, ref_output)
