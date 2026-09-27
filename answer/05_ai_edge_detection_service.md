# 05. Dịch vụ AI (Edge Detection Services)

Quá trình tách viền thực tế được xử lý bởi 1 trong 2 service cốt lõi này tùy theo lựa chọn của người dùng. Cả 2 service đều nhận ảnh mảng byte, thông số cấu hình và trả về mảng byte PNG ảnh viền.

## 1. `lib/core/processingAI/server_edge_detection_service.dart` (Server Processing)

Đây là cỗ máy chính có chất lượng cao nhất, chạy thuật toán mô hình gốc PyTorch (FP32).

### Quá trình hoạt động:
1. **Thiết lập kết nối:** Tạo một `MultipartRequest` HTTP POST gửi đến API Server (ví dụ: `http://192.168.2.22:5000/detect-edges`).
2. **Đóng gói dữ liệu:** 
   - Đính kèm mảng byte ảnh gốc vào field file `image`.
   - Đính kèm các thông số cấu hình AI (Threshold, Soft Edges, Blur, ...) vào các HTTP fields dưới dạng chữ (`settings.threshold.toString()`).
3. **Gửi và Nhận:**
   - Đẩy gói dữ liệu lên Backend server và đợi. Backend Python sẽ áp dụng inference PyTorch, chạy hậu kỳ trên đó và phản hồi lại một ảnh định dạng PNG (`image/png`).
   - Phân tích và convert luồng response thành `Uint8List` để trả ngược về cho UI.

## 2. `lib/core/processingAI/edge_detection_service.dart` (Local TFLite Fallback)

Nếu người dùng chọn tắt Server, hoặc máy chủ lỗi mạng, Service này sẽ hoạt động. Nó sử dụng mô hình TFLite nén nhẹ được đóng gói trực tiếp vào trong app.

### Quá trình hoạt động:
1. **Load AI Model:** Hàm `loadModel()` nạp file `hed_mobile_v2_fp32.tflite`. Cố gắng kích hoạt GPU Delegate (phần cứng đồ họa) để xử lý nhanh hơn tránh giật điện thoại.
2. **Inference (Suy luận xác suất):**
   - Hàm `runInference()` decode ảnh thành dạng `Image`, dùng padding để đưa nó về ảnh vuông `256x256` (tránh méo tỷ lệ). 
   - Áp dụng chuẩn hóa ImageNet (đưa màu sắc về khoảng trung bình) và đẩy vào tensor 3 kênh RGB.
   - Nhận về kết quả là mảng 2 chiều (`probMap`) chứa xác suất [0.0 - 1.0] xem mỗi điểm ảnh có phải là đường viền hay không.
3. **Hậu kỳ (Post-Processing) Native:**
   - Hàm `applyPostProcessing()` đẩy `probMap` và các Settings vào một Thread phụ (`Isolate` - thông qua hàm `compute()`) để không làm đơ giao diện.
   - Sử dụng package `opencv_dart` gọi lõi thư viện C++ OpenCV nguyên bản. Xử lý thuật toán `Sigmoid Contrast` (làm mượt đường cong), `Gaussian Blur` (chống răng cưa), và Inverse Color cực nhanh. 
   - Cuối cùng crop, resize lại đúng bằng tỷ lệ ảnh ban đầu và encode thành `Uint8List` PNG.

---
**Tóm tắt bước này:**
Đây là các bộ máy vật lý tính toán cực nặng. Kết quả cuối cùng do chúng cung cấp là mảng byte (`edgeBytes`) đại diện cho bức tranh đã tách hết phông nền và chỉ còn lại nét vẽ đen trắng chuẩn.
