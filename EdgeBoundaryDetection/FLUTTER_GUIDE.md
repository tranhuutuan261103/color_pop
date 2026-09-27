# Hướng dẫn tích hợp AI Model (PyTorch) vào Flutter bằng TFLite

Tài liệu này hướng dẫn chi tiết từng bước cách bạn chuyển đổi mô hình HED (PyTorch) sang TFLite, tối ưu hóa cho Mobile GPU và nhúng trực tiếp vào dự án Flutter khác.

## Phần 1: Chuyển đổi mô hình sang TFLite

Trong thư mục dự án `EdgeBoundaryDetection`, mình đã tạo sẵn cho bạn một file script là `export_tflite.py`. File này thực hiện các bước sau:
1. **Tạo Wrapper:** Bọc mô hình HED lại để nhận đầu vào là ảnh **RGBA (4 kênh)** (phù hợp với ảnh từ Camera điện thoại) và chỉ trả về một output duy nhất (fused edge map) thay vì 6 outputs.
2. **Xuất ra ONNX:** Lưu mô hình lại dưới dạng trung gian ONNX.
3. **Chuyển đổi sang TFLite:** Sử dụng `onnx2tf` và TensorFlow để tạo ra file `.tflite`.
4. **Quantization (Lượng tử hóa):** Áp dụng chuẩn Float16 Quantization để giảm dung lượng file xuống một nửa, tải lên GPU nhanh hơn mà không làm giảm độ chính xác đáng kể.

### Bước thực hiện:
Mở terminal tại thư mục dự án `EdgeBoundaryDetection` và cài đặt các thư viện cần thiết:
```bash
pip install onnx tensorflow onnx2tf
```

Sau đó chạy script chuyển đổi:
```bash
python export_tflite.py
```

Khi chạy xong, bạn sẽ thu được file **`hed_mobile_quant.tflite`**. Đây chính là file mô hình tối ưu nhất để mang sang Flutter.

---

## Phần 2: Tích hợp vào ứng dụng Flutter

Dưới đây là các bước để đưa mô hình `hed_mobile_quant.tflite` vào dự án ứng dụng Flutter của bạn.

### Bước 1: Thêm mô hình vào Assets
1. Copy file `hed_mobile_quant.tflite` và tạo một thư mục tên là `assets` trong thư mục gốc của project Flutter của bạn (nếu chưa có).
2. Dán file vào thư mục `assets`.
3. Mở file `pubspec.yaml` của project Flutter và khai báo thư mục assets:

```yaml
flutter:
  assets:
    - assets/hed_mobile_quant.tflite
```

### Bước 2: Cài đặt thư viện TFLite cho Flutter
Sử dụng package `tflite_flutter` (package phổ biến nhất để chạy TFLite trên C++ engine) và thư viện hình ảnh `image` để xử lý pixel. Chạy lệnh sau trong thư mục project Flutter:

```bash
flutter pub add tflite_flutter image
```

> **Lưu ý quan trọng trên Android:** Bạn hãy mở `android/app/build.gradle` và chặn nén file tflite bằng cách thêm đoạn mã này vào khối `android { ... }`:
> ```gradle
> android {
>     ...
>     aaptOptions {
>         noCompress "tflite"
>     }
> }
> ```

### Bước 3: Khởi tạo mô hình với GPU Delegate (Dart)
Tạo một file Dart mới (ví dụ: `lib/services/edge_detection_service.dart`) và viết mã để khởi tạo Interpreter. Lưu ý chúng ta sẽ kích hoạt GPU Delegate ở đây.

```dart
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';

class EdgeDetectionService {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    try {
      final interpreterOptions = InterpreterOptions();

      // Sử dụng GPU Delegate để tăng tốc độ tính toán
      if (Platform.isAndroid) {
        // Tích hợp GPU Delegate trên Android (OpenGL ES)
        interpreterOptions.addDelegate(GpuDelegateV2());
      } else if (Platform.isIOS) {
        // Tích hợp GPU Delegate trên iOS (Metal)
        interpreterOptions.addDelegate(GpuDelegate());
      }

      // Nạp file mô hình đã lượng tử hoá
      _interpreter = await Interpreter.fromAsset(
        'assets/hed_mobile_quant.tflite',
        options: interpreterOptions,
      );
      print('Model loaded successfully');
    } catch (e) {
      print('Failed to load model: $e');
    }
  }

  void close() {
    _interpreter?.close();
  }
}
```

### Bước 4: Xử lý dữ liệu (Inference) từ ảnh Camera RGBA
Vì trong bước 1, chúng ta đã tối ưu mô hình để nhận trực tiếp mảng **RGBA [1, 4, 256, 256]**, bạn không cần phải dùng vòng lặp loại bỏ kênh Alpha bằng CPU trong Flutter (tránh được "cổ chai" CPU hiệu năng).

Dưới đây là mã chạy Inference (dự đoán):

```dart
import 'dart:typed_data';
import 'package:image/image.dart' as img;

extension EdgeInference on EdgeDetectionService {
  /// Dự đoán và trả về ảnh kết quả đen trắng (Cạnh)
  Future<Uint8List?> detectEdges(Uint8List imageBytes) async {
    if (_interpreter == null) return null;

    // 1. Giải mã ảnh đầu vào
    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return null;

    // 2. Resize ảnh về kích thước mô hình mong muốn (256x256)
    img.Image resizedImage = img.copyResize(originalImage, width: 256, height: 256);

    // 3. Chuyển đổi pixel sang Tensor RGBA [1, 4, 256, 256]
    // Vì ảnh decode mặc định có kênh định dạng RGBA (hoặc có thể ép sang RGBA)
    var inputTensor = List.generate(
      1,
      (i) => List.generate(
        4, // 4 kênh: R, G, B, A
        (c) => List.generate(
          256,
          (y) => List.generate(256, (x) {
            final pixel = resizedImage.getPixel(x, y);
            // Chuẩn hoá giá trị pixel về [0, 1] nếu mô hình đào tạo theo [0, 1]
            if (c == 0) return pixel.r / 255.0;
            if (c == 1) return pixel.g / 255.0;
            if (c == 2) return pixel.b / 255.0;
            return pixel.a / 255.0; // Alpha
          }),
        ),
      ),
    );

    // 4. Chuẩn bị biến output Tensor [1, 1, 256, 256]
    var outputTensor = List.generate(
      1,
      (i) => List.generate(
        1,
        (c) => List.generate(
          256,
          (y) => List.generate(256, (x) => 0.0),
        ),
      ),
    );

    // 5. Chạy mô hình (Inference)
    // TFLite C++ engine sẽ xử lý dữ liệu và đẩy xuống GPU tự động
    _interpreter!.run(inputTensor, outputTensor);

    // 6. Xây dựng lại ảnh từ output (ma trận 256x256 với giá trị 0.0 -> 1.0)
    img.Image outputImage = img.Image(width: 256, height: 256);
    for (int y = 0; y < 256; y++) {
      for (int x = 0; x < 256; x++) {
        // Giá trị dự đoán (0-1) nhân với 255 để thành thang độ xám
        int edgeVal = (outputTensor[0][0][y][x] * 255).clamp(0, 255).toInt();
        
        // Gán pixel thang độ xám (Gray)
        outputImage.setPixelRgb(x, y, edgeVal, edgeVal, edgeVal);
      }
    }

    // Trả về ảnh ở dạng JPG/PNG byte để hiển thị lên Flutter Widget
    return Uint8List.fromList(img.encodePng(outputImage));
  }
}
```

> **Memory & RESHAPE:** 
> - Việc sử dụng mảng Fixed-size `[1, 4, 256, 256]` trực tiếp mà không cần dùng các hàm Reshape hay Transpose trong Flutter giúp mô hình khi đưa vào GPU cực kỳ tối ưu, đúng như nguyên tắc "Hạn chế tối đa toán tử thay đổi hình dạng (RESHAPE)".
> - GPU Delegate sẽ tự động fall-back kênh Alpha về CPU hoặc lờ đi do ta đã sử dụng hàm cắt `x_rgb = x[:, :3, :, :]` ở Wrapper Python.

### Bước 5: Sử dụng trên Giao diện
Tại file UI (ví dụ `main.dart`):

```dart
// Khởi tạo model ở initState
final _edgeService = EdgeDetectionService();
@override
void initState() {
  super.initState();
  _edgeService.loadModel();
}

// Chạy và hiển thị ảnh
Uint8List? _resultImage;

void _processImage(Uint8List cameraBytes) async {
  final result = await _edgeService.detectEdges(cameraBytes);
  setState(() {
    _resultImage = result;
  });
}

// Hiển thị:
// _resultImage != null ? Image.memory(_resultImage!) : SizedBox(),
```
