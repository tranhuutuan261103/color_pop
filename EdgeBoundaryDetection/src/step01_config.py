import os
from dataclasses import dataclass

@dataclass
class Config:
    # Dataset config
    dataset_dir: str = "/root/dataset" if os.environ.get("MODAL_ENVIRONMENT") else "dataset/processed/BSDS500"
    train_dir: str = "train"
    val_dir: str = "val"
    test_dir: str = "test"
    
    # Model config
    pretrained_vgg: bool = True
    
    # Training config
    batch_size: int = 4 # We can use batch_size > 1 because dataset now crops to 256x256
    gradient_accumulation_steps: int = 4 # Effective batch size = 4 * 4 = 16
    epochs: int = 50
    lr: float = 3e-4 # Better learning rate for AdamW
    weight_decay: float = 1e-4
    
    # Checkpoint
    checkpoint_dir: str = "/root/checkpoints" if os.environ.get("MODAL_ENVIRONMENT") else "checkpoints"
    save_freq: int = 5 # Save every 5 epochs
    
config = Config()
