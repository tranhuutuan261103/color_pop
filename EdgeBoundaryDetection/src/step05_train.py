import os
import torch
import torch.optim as optim
from torch.optim.lr_scheduler import StepLR
import time
import torch.nn.functional as F

try:
    from src.step01_config import config
    from src.step02_dataset import get_dataloader
    from src.step03_model import HED
    from src.step04_loss import HEDLoss
except ImportError:
    pass # handled in main

def calculate_metrics(preds, targets, threshold=0.5):
    # Preds is the fused output (last element of HED outputs), shape (B, 1, H, W)
    probs = torch.sigmoid(preds)
    preds_binary = (probs > threshold).float()
    
    tp = (preds_binary * targets).sum().item()
    fp = (preds_binary * (1 - targets)).sum().item()
    fn = ((1 - preds_binary) * targets).sum().item()
    
    precision = tp / (tp + fp + 1e-8)
    recall = tp / (tp + fn + 1e-8)
    f1 = 2 * (precision * recall) / (precision + recall + 1e-8)
    
    return precision, recall, f1

def validate(model, dataloader, criterion, device):
    model.eval()
    val_loss = 0.0
    total_precision = 0.0
    total_recall = 0.0
    total_f1 = 0.0
    
    with torch.no_grad():
        for images, masks in dataloader:
            images = images.to(device)
            masks = masks.to(device)
            
            outputs = model(images)
            loss = criterion(outputs, masks)
            val_loss += loss.item()
            
            # Use the 6th output (fused output) for metrics
            fused_output = outputs[-1]
            p, r, f1 = calculate_metrics(fused_output, masks)
            
            total_precision += p
            total_recall += r
            total_f1 += f1
            
    num_batches = len(dataloader)
    return (val_loss / num_batches, 
            total_precision / num_batches, 
            total_recall / num_batches, 
            total_f1 / num_batches)

def train_epoch(model, dataloader, optimizer, criterion, device, epoch):
    model.train()
    running_loss = 0.0
    
    start_time = time.time()
    optimizer.zero_grad() # Zero grad initially for accumulation
    
    for i, (images, masks) in enumerate(dataloader):
        images = images.to(device)
        masks = masks.to(device)
        
        outputs = model(images)
        loss = criterion(outputs, masks)
        
        # Scale the loss to account for gradient accumulation
        scaled_loss = loss / config.gradient_accumulation_steps
        scaled_loss.backward()
        
        # Step and zero_grad only every 'gradient_accumulation_steps' or at the end of epoch
        if (i + 1) % config.gradient_accumulation_steps == 0 or (i + 1) == len(dataloader):
            optimizer.step()
            optimizer.zero_grad()
            
        running_loss += loss.item()
        
        if (i + 1) % 50 == 0:
            print(f"Epoch [{epoch+1}/{config.epochs}], Step [{i+1}/{len(dataloader)}], Train Loss: {loss.item():.4f}")
            
    epoch_loss = running_loss / len(dataloader)
    elapsed_time = time.time() - start_time
    print(f"Epoch [{epoch+1}/{config.epochs}] Train complete. Avg Loss: {epoch_loss:.4f}. Time: {elapsed_time:.2f}s")
    
    return epoch_loss

def run_training():
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"Using device: {device}")
    
    model = HED(pretrained_vgg=config.pretrained_vgg).to(device)
    criterion = HEDLoss()
    optimizer = optim.AdamW(model.parameters(), lr=config.lr, weight_decay=config.weight_decay)
    scheduler = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=config.epochs, eta_min=1e-6)
    
    print(f"Loading dataset from: {config.dataset_dir}")
    train_loader = get_dataloader(config.dataset_dir, split=config.train_dir, batch_size=config.batch_size)
    val_loader = get_dataloader(config.dataset_dir, split=config.val_dir, batch_size=1, shuffle=False)
    
    os.makedirs(config.checkpoint_dir, exist_ok=True)
    
    best_f1 = 0.0
    best_model_path = os.path.join(config.checkpoint_dir, 'best_model.pth')
    
    print("Starting training with Validation Loop...")
    for epoch in range(config.epochs):
        train_loss = train_epoch(model, train_loader, optimizer, criterion, device, epoch)
        
        print("Running validation...")
        val_loss, val_p, val_r, val_f1 = validate(model, val_loader, criterion, device)
        print(f"Validation -> Loss: {val_loss:.4f} | Precision: {val_p:.4f} | Recall: {val_r:.4f} | F1-Score: {val_f1:.4f}")
        
        if val_f1 > best_f1:
            best_f1 = val_f1
            torch.save({
                'epoch': epoch + 1,
                'model_state_dict': model.state_dict(),
                'optimizer_state_dict': optimizer.state_dict(),
                'f1_score': best_f1
            }, best_model_path)
            print(f"*** New Best Model Saved! F1: {best_f1:.4f} ***")
            
        scheduler.step()
        
        if (epoch + 1) % config.save_freq == 0:
            checkpoint_path = os.path.join(config.checkpoint_dir, f'hed_epoch_{epoch+1}.pth')
            torch.save({
                'epoch': epoch + 1,
                'model_state_dict': model.state_dict(),
                'optimizer_state_dict': optimizer.state_dict(),
            }, checkpoint_path)
            
    print("Training finished!")
    return best_model_path

if __name__ == "__main__":
    run_training()
