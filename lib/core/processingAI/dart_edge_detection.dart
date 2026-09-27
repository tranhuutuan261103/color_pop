import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class DartEdgeDetection {
  
  /// Applies a Sobel filter to extract edges from an image.
  static Future<Uint8List?> applySobel(Uint8List imageBytes) async {
    return compute(_sobelCompute, imageBytes);
  }

  /// Applies a simplified Canny-like filter (Sobel + Threshold + Morphological ops or stronger threshold).
  /// For simplicity in pure Dart without OpenCV, we use strong luminance + sobel + threshold.
  static Future<Uint8List?> applyCanny(Uint8List imageBytes) async {
    return compute(_cannyCompute, imageBytes);
  }

  // Running image processing in an isolate (compute) to prevent blocking the main UI thread.
  static Uint8List? _sobelCompute(Uint8List bytes) {
    try {
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      // Convert to grayscale
      img.grayscale(image);
      
      // Apply Sobel edge detection
      img.Image edgeImage = img.sobel(image);
      
      // Invert image so edges are black on white background
      img.invert(edgeImage);
      
      // Manually threshold to ensure solid black lines and white background, with no alpha issues
      for (int y = 0; y < edgeImage.height; y++) {
        for (int x = 0; x < edgeImage.width; x++) {
          final pixel = edgeImage.getPixel(x, y);
          // Calculate luminance
          final luminance = (pixel.r * 299 + pixel.g * 587 + pixel.b * 114) / 1000;
          if (luminance > 230) {
            edgeImage.setPixelRgb(x, y, 255, 255, 255); // White background
          } else {
            edgeImage.setPixelRgb(x, y, 0, 0, 0); // Black edges
          }
        }
      }

      return Uint8List.fromList(img.encodePng(edgeImage));
    } catch (e) {
      debugPrint("Error in Sobel compute: $e");
      return null;
    }
  }

  static Uint8List? _cannyCompute(Uint8List bytes) {
    try {
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      // Convert to grayscale
      img.grayscale(image);
      
      // Canny usually involves Gaussian Blur -> Sobel -> Non-maximum suppression -> Double Threshold.
      // Since `image` package doesn't have a full Canny implementation, we approximate it:
      
      // 1. Blur to reduce noise
      img.gaussianBlur(image, radius: 2);
      
      // 2. Sobel
      img.Image edgeImage = img.sobel(image);
      
      // 3. Invert
      img.invert(edgeImage);
      
      // 4. Manually threshold for strong edges
      for (int y = 0; y < edgeImage.height; y++) {
        for (int x = 0; x < edgeImage.width; x++) {
          final pixel = edgeImage.getPixel(x, y);
          final luminance = (pixel.r * 299 + pixel.g * 587 + pixel.b * 114) / 1000;
          if (luminance > 215) {
            edgeImage.setPixelRgb(x, y, 255, 255, 255);
          } else {
            edgeImage.setPixelRgb(x, y, 0, 0, 0);
          }
        }
      }

      return Uint8List.fromList(img.encodePng(edgeImage));
    } catch (e) {
      debugPrint("Error in Canny compute: $e");
      return null;
    }
  }
}
