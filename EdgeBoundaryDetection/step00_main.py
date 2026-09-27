import modal
import os

# Create the Modal app
app = modal.App("hed-edge-detection")

# Define the container image with PyTorch and dependencies
# We also use add_local_dir to bundle the dataset and src code directly into the container
image = (
    modal.Image.debian_slim(python_version="3.10")
    .pip_install("torch", "torchvision", "Pillow", "numpy", "albumentations==1.3.1", "opencv-python-headless")
    .env({"MODAL_ENVIRONMENT": "1"})
    .add_local_dir(local_path="./dataset/processed/BSDS500", remote_path="/root/dataset")
    .add_local_dir(local_path="./src", remote_path="/root/src")
)

# Create a volume to save checkpoints during training
checkpoint_volume = modal.Volume.from_name("hed-checkpoints", create_if_missing=True)

# Define the Modal function that runs on a cloud GPU (e.g., T4)
@app.function(
    image=image, 
    gpu="T4", 
    volumes={"/root/checkpoints": checkpoint_volume},
    timeout=86400 # 24 hours
)
def train_on_modal():
    print("--- Starting HED Training on Modal GPU ---")
    
    # Ensure /root is in sys.path so we can import src
    import sys
    if "/root" not in sys.path:
        sys.path.append("/root")
        
    # We import the training script inside the function so it runs in the cloud environment
    from src.step05_train import run_training
    
    # Run the training loop (returns best_model.pth path)
    best_checkpoint_path = run_training()
    
    # Commit the volume to ensure files are saved
    checkpoint_volume.commit()
    
    # Read the checkpoints into memory to return to local machine
    print(f"Reading best checkpoint {best_checkpoint_path} to send back to local...")
    best_checkpoint_data = None
    if os.path.exists(best_checkpoint_path):
        with open(best_checkpoint_path, "rb") as f:
            best_checkpoint_data = f.read()
        
    return best_checkpoint_data, 'best_model.pth'

@app.local_entrypoint()
def main():
    print("Deploying to Modal and starting training...")
    best_data, best_name = train_on_modal.remote()
    
    print("Training complete! Downloading checkpoints to local machine...")
    local_checkpoint_dir = "./checkpoints"
    os.makedirs(local_checkpoint_dir, exist_ok=True)
        
    if best_data:
        local_best = os.path.join(local_checkpoint_dir, best_name)
        with open(local_best, "wb") as f:
            f.write(best_data)
        print(f"Success! Best checkpoint saved to: {local_best}")
        
    print("You can also view all checkpoints on your Modal dashboard (Volumes -> hed-checkpoints).")
