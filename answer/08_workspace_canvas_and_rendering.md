# 08. Không gian vẽ đồ họa (Canvas & Rendering)

Sau khi bộ máy Controller và IO đã nạp xong file `.cpop` thành đối tượng `ColorPopDocument`, dữ liệu đã thực sự hoàn chỉnh để hiển thị cho người dùng nhìn thấy. Khối lượng công việc khổng lồ này được thực hiện tại một Widget cốt lõi.

## File: `lib/features/creator/widget/workspace_canvas.dart`

Widget này là linh hồn của màn hình tương tác, chịu trách nhiệm vẽ ra toàn bộ nét viền AI, những mảng màu người dùng đổ vào và bắt sự kiện từ ngón tay.

### Quá trình hoạt động:

1. **Bộ khung `InteractiveViewer`:**
   - Wrap bên ngoài toàn bộ để cung cấp khả năng Pan (di chuyển) và Zoom (phóng to lên tới 10x) cho khung tranh.
   - Tọa độ phóng to/thu nhỏ này sẽ được đồng bộ hóa với hệ thống vẽ.

2. **Hệ thống Vẽ 2 Lớp (Dual Layer Rendering):**
   Giao diện Canvas sử dụng kiến trúc vẽ 2 lớp đè lên nhau để tối ưu hóa hiệu suất (lên tới 120 FPS):
   
   * **LỚP NỀN (Base Layer - Tĩnh):** 
     - Là Widget `CustomPaint` bọc trong `RepaintBoundary`. Nó nhận `HybridRenderer(document)` để vẽ.
     - `HybridRenderer` đọc dữ liệu vector từ `ColorPopDocument` và vẽ ra toàn bộ các nét đen của AI trên mặt phẳng gốc, đồng thời vẽ luôn những vùng người dùng đã dùng thùng sơn đổ màu.
     - Đây là lớp siêu nặng, nhưng nhờ `RepaintBoundary`, Flutter sẽ "chụp màn hình" và cache nó lại thành tĩnh, không bắt chip đồ họa phải vẽ lại liên tục khi chưa có sự kiện nào thay đổi đáng kể.

   * **LỚP ĐỘNG (Active Layer - Động):**
     - Là lớp mặt nạ trong suốt đè lên trên, chỉ kích hoạt khi người dùng dùng Bút vẽ hoặc Cục tẩy.
     - Sử dụng `ValueListenableBuilder` liên kết trực tiếp với luồng `activeStrokeNotifier`.
     - Khi ngón tay lướt đi, lớp Động này sẽ vẽ chỉ 1 nét đang tương tác đó `ActiveLayerPainter`. Nó dùng hệ thống **Clipping Mask** để đảm bảo dù ngón tay quẹt sai, màu cũng bị tàng hình khi tràn ra ngoài viền AI. Khi ngón tay nhấc lên, nét vẽ này được sáp nhập ngược xuống LỚP NỀN.

3. **Bắt sự kiện (Touch Listener):**
   - Lớp màn trong suốt trên cùng bao bọc bởi Widget `Listener` để bắt trực tiếp tọa độ vật lý theo Pixel khi người dùng chạm (`onPointerDown`), di chuyển (`onPointerMove`), thả tay (`onPointerUp`).
   - Tọa độ này gửi sang `Controller`. Nếu là công cụ Đổ màu, `Controller` truyền tọa độ x,y đó xuống hệ thống Cây tìm kiếm (`SpatialIndex`). Nó tra ra ID vùng, đẩy màu xuống `PaintEngine`, Cập nhật LỚP NỀN và thế là bức tranh của AI đã được đổ màu gọn gàng!

---
**TÓM TẮT TOÀN BỘ QUÁ TRÌNH TỪ MAIN ĐẾN APP:**
1. Mở App (`main.dart`).
2. Chọn "AI Model", mở Thư viện lấy ảnh (`creator_screen.dart`).
3. Chỉnh Threshold, chọn Server/Local AI (`edge_settings_screen.dart`).
4. Gửi ảnh vào AI, nhận viền nét đen, Preview kết quả (`edge_preview_screen.dart` & `server_edge_detection_service.dart`).
5. Đẩy ảnh viền vào Workspace (`workspace_screen.dart`).
6. Chuyển PNG viền thành Vector .cpop qua C++ (`workspace_io_manager.dart` & `workspace_logic.dart`).
7. Tải file Vector lên màn hình Canvas, tô màu (`workspace_canvas.dart`).
**QUÁ TRÌNH HOÀN TẤT.**
