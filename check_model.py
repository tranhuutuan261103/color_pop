import tensorflow as tf
import numpy as np
import PIL.Image as Image
import torchvision.transforms as transforms

# Load an image
img = Image.new('RGB', (256, 256), color = 'white') # Dummy image
transform = transforms.Compose([
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])
img_tensor = transform(img).unsqueeze(0)
# TFLite takes NHWC and 4 channels
dummy_input = np.zeros((1, 256, 256, 4), dtype=np.float32)

interpreter = tf.lite.Interpreter(model_path="assets/hed_mobile_quant.tflite")
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

interpreter.set_tensor(input_details[0]['index'], dummy_input)
interpreter.invoke()
output_data = interpreter.get_tensor(output_details[0]['index'])

print(f"Min: {np.min(output_data)}, Max: {np.max(output_data)}")
