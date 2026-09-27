import torch
import torch.nn as nn
import torch.nn.functional as F

class HEDLoss(nn.Module):
    """
    Class-balanced Cross Entropy Loss + Dice Loss for HED.
    Calculates the loss for all 5 side outputs and the fused output.
    """
    def __init__(self):
        super(HEDLoss, self).__init__()

    def dice_loss(self, pred, target, smooth=1e-5):
        # Convert logits to probabilities
        pred = torch.sigmoid(pred)
        
        # Calculate intersection and union
        intersection = (pred * target).sum()
        union = pred.sum() + target.sum()
        
        dice = (2. * intersection + smooth) / (union + smooth)
        return 1.0 - dice

    def forward(self, preds, target):
        """
        preds: list of 6 tensors (5 side outputs + 1 fused output), each of shape (B, 1, H, W)
        target: tensor of shape (B, 1, H, W)
        """
        loss = 0.0
        
        for pred in preds:
            # Calculate dynamic weight for each batch
            pos_pixels = target.sum()
            total_pixels = target.numel()
            neg_pixels = total_pixels - pos_pixels
            
            # Avoid division by zero if an image has no edge
            if pos_pixels == 0:
                pos_weight = torch.tensor(1.0, device=target.device)
            else:
                # Limit max pos_weight to prevent exploding gradients when edge is very thin/rare
                pos_weight = torch.clamp(neg_pixels / pos_pixels, max=100.0)
            
            # BCEWithLogitsLoss combines Sigmoid and BCE
            bce_loss = F.binary_cross_entropy_with_logits(
                pred, target, pos_weight=pos_weight, reduction='mean'
            )
            
            # Dice Loss to improve edge connectivity
            d_loss = self.dice_loss(pred, target)
            
            # Total loss is combination of both
            loss += bce_loss + d_loss
            
        return loss

if __name__ == "__main__":
    # Test the loss
    loss_fn = HEDLoss()
    preds = [torch.randn(1, 1, 256, 256) for _ in range(6)]
    target = torch.randint(0, 2, (1, 1, 256, 256)).float()
    loss = loss_fn(preds, target)
    print(f"HED Loss: {loss.item()}")
