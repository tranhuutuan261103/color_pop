import torch
import tensorflow as tf
import numpy as np
from PIL import Image
import torchvision.transforms as transforms
import cv2
import sys
import os

# Create a simple test image (e.g. a black square on a white background)
img_np = np.ones((256, 256, 3), dtype=np.uint8) * 255
cv2.rectangle(img_np, (50, 50), (200, 200), (0, 0, 0), 10)
img = Image.fromarray(img_np)
img.save("test_input.png")

# Normalize like web_app
transform = transforms.Compose([
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])
img_tensor = transform(img).unsqueeze(0) # [1, 3, 256, 256]

# 1. RUN PYTORCH MODEL (if available)
try:
    sys.path.append(os.path.join(os.getcwd(), 'EdgeBoundaryDetection'))
    from src.step03_model import HED
    device = torch.device('cpu')
    model = HED(pretrained_vgg=False).to(device)
    checkpoint = torch.load("EdgeBoundaryDetection/checkpoints/best_model.pth", map_location=device)
    model.load_state_dict(checkpoint['model_state_dict'])
    model.eval()
    
    with torch.no_grad():
        outputs = model(img_tensor)
        fused_output = outputs[-1]
        prob = torch.sigmoid(fused_output)
        edge_map_pth = prob[0, 0].numpy()
        
    cv2.imwrite("test_out_pth.png", (edge_map_pth * 255).astype(np.uint8))
    print("PyTorch model generated successfully.")
except Exception as e:
    print("PyTorch error:", e)

# 2. RUN TFLITE MODEL
try:
    interpreter = tf.lite.Interpreter(model_path="assets/hed_mobile_quant.tflite")
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    # We need to feed [1, 256, 256, 4]. Let's try to map the 3 channels to the first 3 of the 4.
    # What does the TFLite model expect?
    img_np_norm = np.zeros((1, 256, 256, 4), dtype=np.float32)
    # img_tensor is [1, 3, 256, 256]
    # convert to NHWC [1, 256, 256, 3]
    nhwc = img_tensor.numpy().transpose(0, 2, 3, 1)
    img_np_norm[0, :, :, :3] = nhwc[0]
    # leave 4th channel as 0
    
    interpreter.set_tensor(input_details[0]['index'], img_np_norm)
    interpreter.invoke()
    tflite_out = interpreter.get_tensor(output_details[0]['index'])
    
    edge_map_tflite = tflite_out[0, :, :, 0]
    cv2.imwrite("test_out_tflite.png", (edge_map_tflite * 255).astype(np.uint8))
    print("TFLite model generated successfully.")
    print("TFLite min/max:", np.min(edge_map_tflite), np.max(edge_map_tflite))
except Exception as e:
    print("TFLite error:", e)
