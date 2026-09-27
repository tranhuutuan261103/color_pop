# 04. Chạy AI và Xem trước (Edge Preview Screen)

## File: `lib/features/creator/view/edge_preview_screen.dart`

Đây là "trái tim" của tính năng AI. Màn hình này nhận mảng byte ảnh gốc (`imageBytes`) cùng các thông số cấu hình và bắt đầu quá trình tách viền.

### Quá trình hoạt động:

1. **Khởi tạo và chạy Inference (Suy luận AI):**
   - Khi màn hình được mở (`initState`), nó gọi hàm `_runInference()`.
   - **Nếu dùng Server (`useServer == true`):** Chuyển trực tiếp sang bước Post-processing (gọi API server).
   - **Nếu dùng Local TFLite:** Nó gọi `EdgeDetectionService` để load mô hình (`loadModel`) và phân tích ảnh gốc ra một "bản đồ xác suất" (`probMap`) kích thước 256x256. Bước inference này khá nặng, nhưng chỉ chạy **DUY NHẤT 1 LẦN** để giữ lấy kết quả gốc `_inferenceResult`.

2. **Xử lý hậu kỳ (Post Processing) & Real-time Update:**
   - Hàm `_applyPostProcessing()` được gọi để tạo ra ảnh viền hoàn chỉnh.
   - Khi người dùng kéo các thanh trượt thông số ở giao diện bên dưới, nhờ có hàm `_updateSettings` áp dụng Timer Debounce (300ms), nó sẽ gọi lại `_applyPostProcessing()` liên tục để tạo ra ảnh preview mới.
   - Quá trình hậu kỳ này diễn ra rất nhanh:
     - Với Local: Chạy cô lập trên một Thread riêng biệt (Isolate) thông qua package `opencv_dart` để áp dụng các bộ lọc (Sigmoid, Invert, Resize về tỷ lệ gốc).
     - Với Server: Gọi HTTP request mới lên server.

3. **Fallback (Dự phòng):**
   - Nếu trong quá trình gọi API Server mà kết nối mạng lỗi, màn hình tự động thiết lập lại `_useServer = false` và chuyển qua load mô hình Local TFLite để phân tích ảnh, đảm bảo app không bao giờ bị đứng.

4. **Xác nhận (Apply):**
   - Khi người dùng hài lòng với bức ảnh đang hiển thị và ấn nút **"Apply"** ở góc trên, hàm `_onApply()` chạy.
   - Chạy lại xử lý ở độ phân giải gốc.
   - Nhận về `fullResResult` dạng mảng Byte PNG đen trắng (Lineart).
   - Cuối cùng gọi `Navigator.pop(context, { 'edgeBytes': fullResResult, ... })` để đưa bức tranh đã hoàn thiện về lại cho `CreatorScreen` (chuyển sang bước Workspace).

---
**Tóm tắt bước này:**
Màn hình nhận ảnh gốc, gọi AI Service (chạy 1 lần), nhận kết quả thô, dùng thuật toán hậu kỳ để biến nó thành ảnh rõ nét. Cung cấp UI cho người dùng kéo thả slider thấy kết quả tức thì. Khi chốt, xuất ra `edgeBytes` (ảnh PNG viền) cuối cùng.
