import torch
import torch.nn as nn
from torchvision import models

class HED(nn.Module):
    def __init__(self, pretrained_vgg=True):
        super(HED, self).__init__()
        
        # Load VGG16 with optional pretrained weights
        if pretrained_vgg:
            # According to deprecation warnings in recent torchvision versions, 
            # we should use weights=VGG16_Weights.DEFAULT if available. 
            # We'll use the backward compatible string for simplicity.
            vgg16 = models.vgg16(pretrained=True)
        else:
            vgg16 = models.vgg16(pretrained=False)
            
        features = list(vgg16.features.children())
        
        # VGG16 blocks
        self.conv1 = nn.Sequential(*features[0:4])
        self.conv2 = nn.Sequential(*features[4:9])
        self.conv3 = nn.Sequential(*features[9:16])
        self.conv4 = nn.Sequential(*features[16:23])
        self.conv5 = nn.Sequential(*features[23:30])

        # Side outputs (1x1 conv to get 1 channel)
        self.side1 = nn.Conv2d(64, 1, kernel_size=1)
        self.side2 = nn.Conv2d(128, 1, kernel_size=1)
        self.side3 = nn.Conv2d(256, 1, kernel_size=1)
        self.side4 = nn.Conv2d(512, 1, kernel_size=1)
        self.side5 = nn.Conv2d(512, 1, kernel_size=1)

        # Upsampling to original size using Bilinear Interpolation
        # Alternatively, transposed convolutions can be used, but Upsample is simpler and standard in modern implementations
        
        # Fusion layer to combine the 5 side outputs
        self.fusion = nn.Conv2d(5, 1, kernel_size=1)
        
        self._initialize_weights(pretrained_vgg)

    def _initialize_weights(self, pretrained_vgg):
        # We only initialize the side and fusion layers if VGG is pretrained
        # Otherwise, everything needs initialization, but PyTorch handles the rest by default
        for m in [self.side1, self.side2, self.side3, self.side4, self.side5, self.fusion]:
            if isinstance(m, nn.Conv2d):
                nn.init.normal_(m.weight, std=0.01)
                if m.bias is not None:
                    nn.init.constant_(m.bias, 0)
        
        if self.fusion is not None:
            nn.init.constant_(self.fusion.weight, 0.2) # equal weight initially

    def forward(self, x):
        h, w = x.shape[2], x.shape[3]
        
        # Pass through VGG blocks
        conv1 = self.conv1(x)
        conv2 = self.conv2(conv1)
        conv3 = self.conv3(conv2)
        conv4 = self.conv4(conv3)
        conv5 = self.conv5(conv4)

        # Side outputs
        side1 = self.side1(conv1)
        side2 = self.side2(conv2)
        side3 = self.side3(conv3)
        side4 = self.side4(conv4)
        side5 = self.side5(conv5)

        # Upsample side outputs to original image size
        side1_up = side1 # already original size
        side2_up = nn.functional.interpolate(side2, size=(h, w), mode='bilinear', align_corners=False)
        side3_up = nn.functional.interpolate(side3, size=(h, w), mode='bilinear', align_corners=False)
        side4_up = nn.functional.interpolate(side4, size=(h, w), mode='bilinear', align_corners=False)
        side5_up = nn.functional.interpolate(side5, size=(h, w), mode='bilinear', align_corners=False)

        # Fusion
        concat = torch.cat([side1_up, side2_up, side3_up, side4_up, side5_up], dim=1)
        fused = self.fusion(concat)
        
        # Returning un-normalized logits because we'll use BCEWithLogitsLoss
        return [side1_up, side2_up, side3_up, side4_up, side5_up, fused]

if __name__ == "__main__":
    # Test the model
    model = HED(pretrained_vgg=False)
    x = torch.randn(1, 3, 256, 256)
    outputs = model(x)
    print(f"Number of outputs: {len(outputs)}")
    for i, out in enumerate(outputs):
        print(f"Output {i} shape: {out.shape}")
