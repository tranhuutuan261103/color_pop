# 07. Quản lý Dữ liệu và Cầu Nối Native C++

Khi `WorkspaceController` bắt đầu, nó gọi hàm `initWorkspace()` để tiến hành quy trình chuyển đổi cuối cùng: Biến bức ảnh PNG đen trắng thành hệ thống Vector (các vùng tô màu được đóng kín).

## 1. `lib/features/creator/controller/workspace_io_manager.dart`

Hàm `initWorkspace()` thực hiện quy trình Load dữ liệu như sau:
1. **Tiếp nhận kết quả AI:** Kiểm tra biến `preProcessedEdgeBytes` truyền vào. Do người dùng đi từ luồng Creator -> Preview AI nên biến này đã có sẵn dữ liệu mảng byte PNG của bức lineart.
2. **Lưu file tạm:** Mảng byte này được ghi thẳng ra một file vật lý tạm thời nằm trong thư mục Cache của điện thoại (ví dụ: `ai_edge_1231241.png`). Dành cho debug, nó còn tự động lưu file này vào thư viện ảnh `ColorPopDebug` thông qua `Gal`.
3. **Gửi file tạm xuống lòng đất (C++ Native):** 
   - Kích hoạt lệnh `WorkspaceLogic.createColorPopDocument(tempEdgePath)`.
4. **Nhận lại file `.cpop` & Giải mã:**
   - Hệ thống C++ xử lý xong sẽ trả về một đường dẫn file kết quả dạng `.cpop`.
   - `ColorPopReader.readFromFile(cpopPath)` được gọi để đọc file `.cpop` nhị phân lên bộ nhớ RAM, biến nó thành đối tượng `ColorPopDocument`.
   - Dùng document này khởi tạo hệ thống tìm kiếm khu vực `SpatialIndex` và động cơ màu sắc `PaintEngine`. Dữ liệu sẵn sàng!

## 2. `lib/core/engine/logic/workspace_logic.dart` (Native Bridge)

File này phụ trách giao tiếp độc quyền với các lớp Native (Android Kotlin/C++ hoặc iOS Swift/C++).
- Sử dụng `MethodChannel('com.fau.color_pop/image_processor')`.
- Gọi hàm kênh Native: `invokeMethod('createColorPopDocument', { 'inputPath': ..., 'outputPath': ... })`.

*(Ở lớp Native C++ phía dưới nền: Hệ thống sẽ load file PNG đen trắng, dùng thuật toán Flood Fill / Contour Trace để tìm ra toàn bộ đường biên khép kín, phân tách bức ảnh thành hàng ngàn mảng không gian riêng biệt (Region Vector). Kết quả này đóng gói thành file nhị phân nén tự thiết kế dạng `.cpop`).*

---
**Tóm tắt bước này:**
Đây là quá trình "Tiến hóa" cuối cùng. Bức ảnh lineart (chỉ là các pixel vô tri) đã được đưa xuống cầu nối Native để hệ thống siêu vi tính của C++ "đọc hiểu", khoanh vùng nó thành các vector. Kết quả `.cpop` được đưa ngược lại Flutter, cung cấp đủ dữ liệu cho người dùng đổ màu vào các mảng trống không bị tràn.
