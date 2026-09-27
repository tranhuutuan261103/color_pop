# 06. Màn hình Workspace và State Controller

Sau khi có trong tay bức ảnh viền (Lineart) từ hệ thống AI dưới định dạng mảng byte (`edgeBytes`), toàn bộ dữ liệu này được Router đẩy sang điểm đến cuối cùng: Màn hình Workspace.

## 1. `lib/features/creator/view/workspace_screen.dart`

Đây là "Khung tranh", nơi gắn kết toàn bộ giao diện cho việc vẽ vời.

### Quá trình hoạt động:
1. **Khởi tạo Bộ não trung tâm:** 
   - Khi `WorkspaceScreen` mở ra, trong `initState()`, nó lập tức tạo ra một bản ghi `WorkspaceController`.
   - Lệnh khởi tạo truyền thẳng `imagePath` và quan trọng nhất là mảng byte AI `preProcessedEdgeBytes` vào.
2. **Dựng giao diện (State Management):**
   - `WorkspaceScreen` sử dụng `ListenableBuilder` lắng nghe `_controller`. Nếu controller đang `isLoading`, nó chỉ xoay vòng tròn chờ đợi. 
   - Khi controller setup xong dữ liệu, nó sẽ vẽ ra các bộ phận: 
     - `WorkspaceAppBar` (Nút back, undo/redo).
     - `WorkspaceCanvas` (Nơi vẽ tranh thật sự).
     - Các bảng màu, kích thước cọ, cục tẩy.
   - Quan trọng: WorkspaceScreen KHÔNG chứa logic nghiệp vụ, nó chỉ nhận lệnh và thông số giao diện từ Controller.

## 2. `lib/features/creator/controller/workspace_controller.dart`

Đây là nơi "hội tụ" kiến trúc của phòng tranh. Nó kế thừa `WorkspaceBaseState` và các Mixin riêng biệt cho từng nhiệm vụ.

### Cấu trúc Mixin:
- **`WorkspaceBaseState`:** Nơi khai báo các biến Global của màn hình này như Màu sắc bút hiện tại, cỡ bút, mảng mảng byte `preProcessedEdgeBytes` nhận được. Chứa các "Động cơ" (`Document`, `PaintEngine`, `SpatialIndex`) sẵn sàng chờ nạp dữ liệu.
- **`WorkspaceIOManager`:** Chuyên phụ trách Khởi động, tải dữ liệu file ảnh, gọi Native để chuyển hệ và lưu ra kết quả (Sẽ giải thích chi tiết ở File 07). Khi `WorkspaceController` khởi tạo, lệnh `initWorkspace()` được gọi nằm ở Mixin này.
- **`WorkspaceTouchHandler`:** Xử lý sự kiện khi ngón tay lướt trên màn hình.
- **`WorkspaceUIHandler`:** Cập nhật hiệu ứng UI thay đổi trạng thái màu, độ dày.

---
**Tóm tắt bước này:**
Bức ảnh viền (`edgeBytes`) đã đến được nơi chứa giao diện tô màu. `WorkspaceScreen` chuẩn bị cọ vẽ, bảng màu và nhường toàn bộ xử lý tải file phức tạp lại cho `WorkspaceController`.
