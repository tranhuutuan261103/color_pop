import os
import torch
import matplotlib.pyplot as plt
import numpy as np

try:
    from src.step01_config import config
    from src.step02_dataset import get_dataloader
    from src.step03_model import HED
except ImportError:
    import sys
    sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    from src.step01_config import config
    from src.step02_dataset import get_dataloader
    from src.step03_model import HED

def unnormalize(tensor):
    mean = torch.tensor([0.485, 0.456, 0.406]).view(3, 1, 1).to(tensor.device)
    std = torch.tensor([0.229, 0.224, 0.225]).view(3, 1, 1).to(tensor.device)
    tensor = tensor * std + mean
    return tensor.clamp(0, 1)

def run_visualization(num_images=20):
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"Using device: {device}")
    
    model = HED(pretrained_vgg=False).to(device)
    
    # Load best model
    best_model_path = os.path.join(config.checkpoint_dir, 'best_model.pth')
    if not os.path.exists(best_model_path):
        print(f"Error: {best_model_path} not found. Please train the model first.")
        return
        
    print(f"Loading weights from {best_model_path}")
    checkpoint = torch.load(best_model_path, map_location=device)
    model.load_state_dict(checkpoint['model_state_dict'])
    model.eval()
    
    print(f"Loading test dataset from: {config.dataset_dir}")
    test_loader = get_dataloader(config.dataset_dir, split=config.test_dir, batch_size=1, shuffle=False)
    
    os.makedirs("answer/visualizations", exist_ok=True)
    
    markdown_content = "# HED Edge Detection Evaluation\n\n"
    markdown_content += "Dưới đây là so sánh trực quan giữa ảnh gốc, nhãn chuẩn (Ground Truth) và kết quả suy luận của mô hình HED (Predicted Edge).\n\n"
    markdown_content += "| Original | Ground Truth | HED Prediction |\n"
    markdown_content += "|---|---|---|\n"
    
    print(f"Processing {num_images} images...")
    
    with torch.no_grad():
        for i, (image, mask) in enumerate(test_loader):
            if i >= num_images:
                break
                
            image = image.to(device)
            mask = mask.to(device)
            
            outputs = model(image)
            fused_output = outputs[-1]
            prob = torch.sigmoid(fused_output)
            
            # Convert tensors to numpy for visualization
            img_np = unnormalize(image[0]).cpu().permute(1, 2, 0).numpy()
            mask_np = mask[0, 0].cpu().numpy()
            pred_np = prob[0, 0].cpu().numpy()
            
            # Save individual images for the markdown table
            img_path = f"answer/visualizations/img_{i}.jpg"
            mask_path = f"answer/visualizations/mask_{i}.png"
            pred_path = f"answer/visualizations/pred_{i}.png"
            
            plt.imsave(img_path, img_np)
            plt.imsave(mask_path, mask_np, cmap='gray')
            plt.imsave(pred_path, pred_np, cmap='gray')
            
            # Add to markdown
            # Using relative paths for markdown rendering
            markdown_content += f"| ![Original](visualizations/img_{i}.jpg) | ![Ground Truth](visualizations/mask_{i}.png) | ![Prediction](visualizations/pred_{i}.png) |\n"
            
            print(f"Processed {i+1}/{num_images}")
            
    with open("answer/evaluation_report.md", "w", encoding="utf-8") as f:
        f.write(markdown_content)
        
    print("Visualization complete! Report saved to answer/evaluation_report.md")

if __name__ == "__main__":
    run_visualization(20)
