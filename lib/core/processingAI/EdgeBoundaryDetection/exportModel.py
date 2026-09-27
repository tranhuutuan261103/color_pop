import torch
import torchvision

# 1. Load model của bạn
model = YourModelClass()
model.load_state_dict(torch.load("best_model.pth", map_location="cpu"))
model.eval()

# 2. Tạo một input giả lập đúng với kích thước ảnh model yêu cầu (VD: 3 kênh màu, 256x256)
example_input = torch.rand(1, 3, 256, 256)

# 3. Trace (Dò) model để chuyển sang TorchScript
traced_script_module = torch.jit.trace(model, example_input)

# 4. Tối ưu hóa cho Mobile
from torch.utils.mobile_optimizer import optimize_for_mobile
optimized_module = optimize_for_mobile(traced_script_module)

# 5. Lưu lại file để bỏ vào App
optimized_module._save_for_lite_interpreter("model_mobile.ptl")