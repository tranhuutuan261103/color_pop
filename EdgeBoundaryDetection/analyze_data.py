import os
import cv2
import numpy as np
import matplotlib.pyplot as plt

def analyze_dataset(dataset_dir):
    train_masks_dir = os.path.join(dataset_dir, "processed", "BSDS500", "train", "masks")
    train_images_dir = os.path.join(dataset_dir, "processed", "BSDS500", "train", "images")
    
    mask_files = [f for f in os.listdir(train_masks_dir) if f.endswith('.png')]
    
    total_pixels = 0
    total_edge_pixels = 0
    
    print("Calculating statistics across the training set...")
    for mask_file in mask_files:
        mask_path = os.path.join(train_masks_dir, mask_file)
        # Read as grayscale
        mask = cv2.imread(mask_path, cv2.IMREAD_GRAYSCALE)
        
        total_pixels += mask.size
        # Assuming edges are > 0
        total_edge_pixels += np.count_nonzero(mask)
        
    total_bg_pixels = total_pixels - total_edge_pixels
    edge_ratio = total_edge_pixels / total_pixels * 100
    bg_ratio = total_bg_pixels / total_pixels * 100
    
    print(f"Total Pixels: {total_pixels}")
    print(f"Total Edge Pixels: {total_edge_pixels} ({edge_ratio:.2f}%)")
    print(f"Total Background Pixels: {total_bg_pixels} ({bg_ratio:.2f}%)")
    
    # Save the stats to a text file to be included in the report
    with open("answer/stats.txt", "w") as f:
        f.write(f"Total Pixels: {total_pixels}\n")
        f.write(f"Total Edge Pixels: {total_edge_pixels} ({edge_ratio:.2f}%)\n")
        f.write(f"Total Background Pixels: {total_bg_pixels} ({bg_ratio:.2f}%)\n")
        f.write(f"Recommended positive weight for BCE: {total_bg_pixels / total_edge_pixels:.2f}\n")

    # Pick one image to visualize
    sample_img_name = mask_files[0].replace('.png', '.jpg')
    img_path = os.path.join(train_images_dir, sample_img_name)
    mask_path = os.path.join(train_masks_dir, mask_files[0])
    
    img = cv2.imread(img_path)
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    mask = cv2.imread(mask_path, cv2.IMREAD_GRAYSCALE)
    
    # Run Canny Edge detection
    img_gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    img_blurred = cv2.GaussianBlur(img_gray, (5, 5), 0)
    edges_canny = cv2.Canny(img_blurred, 50, 150)
    
    # Plotting
    plt.figure(figsize=(15, 5))
    
    plt.subplot(1, 3, 1)
    plt.imshow(img_rgb)
    plt.title("Original Image")
    plt.axis('off')
    
    plt.subplot(1, 3, 2)
    plt.imshow(mask, cmap='gray')
    plt.title("Ground Truth (Human Annotated)")
    plt.axis('off')
    
    plt.subplot(1, 3, 3)
    plt.imshow(edges_canny, cmap='gray')
    plt.title("Canny Edge Detector")
    plt.axis('off')
    
    plt.tight_layout()
    plt.savefig("answer/comparison.png")
    print("Saved visualization to answer/comparison.png")

if __name__ == "__main__":
    analyze_dataset("dataset")
