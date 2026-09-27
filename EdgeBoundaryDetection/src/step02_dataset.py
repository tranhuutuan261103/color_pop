import os
import cv2
import numpy as np
import torch
from torch.utils.data import Dataset, DataLoader
import albumentations as A
from albumentations.pytorch import ToTensorV2

class BSDS500Dataset(Dataset):
    """
    Dataset class for BSDS500.
    Expects directory structure:
    root/
        images/
            100075.jpg
            ...
        masks/
            100075.png
            ...
    """
    def __init__(self, root_dir, split="train", transform=None):
        self.root_dir = root_dir
        self.split = split
        self.split_dir = os.path.join(self.root_dir, split)
        self.images_dir = os.path.join(self.split_dir, "images")
        self.masks_dir = os.path.join(self.split_dir, "masks")
        
        self.image_files = [f for f in os.listdir(self.images_dir) if f.endswith(('.jpg', '.png'))]
        self.transform = transform

    def __len__(self):
        return len(self.image_files)

    def __getitem__(self, idx):
        img_name = self.image_files[idx]
        img_path = os.path.join(self.images_dir, img_name)
        
        base_name = os.path.splitext(img_name)[0]
        mask_path = os.path.join(self.masks_dir, base_name + ".png")

        # Read images using OpenCV (Albumentations standard)
        image = cv2.imread(img_path)
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        
        mask = cv2.imread(mask_path, cv2.IMREAD_GRAYSCALE)

        if self.transform:
            augmented = self.transform(image=image, mask=mask)
            image = augmented['image']
            mask = augmented['mask']
            
        # Ensure mask is float and binary (0 to 1) with shape (1, H, W)
        mask = (mask > 0.0).float()
        mask = mask.unsqueeze(0)

        return image, mask

def get_dataloader(root_dir, split="train", batch_size=1, shuffle=True):
    if split == "train":
        transform = A.Compose([
            A.RandomScale(scale_limit=0.2, p=0.5),
            A.PadIfNeeded(min_height=256, min_width=256, border_mode=cv2.BORDER_CONSTANT, value=0),
            A.RandomCrop(height=256, width=256),
            A.HorizontalFlip(p=0.5),
            A.ColorJitter(brightness=0.3, contrast=0.3, saturation=0.3, hue=0.1, p=0.8),
            A.ShiftScaleRotate(shift_limit=0.1, scale_limit=0, rotate_limit=15, p=0.5),
            A.Normalize(mean=(0.485, 0.456, 0.406), std=(0.229, 0.224, 0.225)),
            ToTensorV2()
        ])
    else:
        transform = A.Compose([
            A.Normalize(mean=(0.485, 0.456, 0.406), std=(0.229, 0.224, 0.225)),
            ToTensorV2()
        ])
        
    dataset = BSDS500Dataset(root_dir, split, transform=transform)
    dataloader = DataLoader(dataset, batch_size=batch_size, shuffle=shuffle, num_workers=2)
    return dataloader
