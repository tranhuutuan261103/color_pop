# 03. Thiết lập thông số AI (Edge Settings Screen)

## File: `lib/features/creator/view/edge_settings_screen.dart`

Ngay sau khi người dùng chọn một bức ảnh, họ được đưa đến màn hình này. Chức năng chính của nó là cho phép người dùng tùy chỉnh cách thuật toán AI sẽ xử lý bức ảnh của họ để tạo ra nét viền (lineart) tối ưu nhất.

### Quá trình hoạt động:

1. **Quản lý dữ liệu cài đặt:**
   - Dữ liệu cấu hình được lưu trong object `EdgeDetectionSettings` (bao gồm: `threshold`, `invertColors`, `useSoftEdges`, `softEdgeClarity`, `gaussianBlurSize`, v.v.).
   - Một cờ `_useServer` (mặc định là `true`) cho phép người dùng chọn chạy AI trên máy chủ đám mây (chất lượng cao) hoặc chạy Offline trên điện thoại bằng mô hình TFLite (chất lượng thấp hơn nhưng không cần mạng).

2. **Giao diện cấu hình (Sliders & Switches):**
   - **Source Selector:** Switch cho phép bật/tắt `Use high-quality server`.
   - **Threshold Slider:** Điều chỉnh ngưỡng cắt nét của AI (Threshold thấp thì lấy được nhiều nét chi tiết hơn, cao thì loại bỏ bớt chi tiết rườm rà).
   - **Invert Colors:** Đảo ngược màu sắc. Mặc định AI tạo ra viền trắng nền đen, Switch này biến nó thành viền đen nền trắng chuẩn của tranh tô màu.
   - **Soft Edges:** Chế độ làm mượt đường viền cao cấp dùng thuật toán Sigmoid Contrast.
   - **Các bộ lọc xử lý ảnh truyền thống (Threshold Mode):** Nếu tắt Soft Edges, UI sẽ hiển thị các thanh kéo cho Gaussian Blur, Morphology (xóa nhiễu/lấp lỗ hổng nét), và Anti-Alias.

3. **Gửi dữ liệu đi:**
   - Khi người dùng nhấn nút **"Preview result"** (Nút Continue), hàm `_continue()` được gọi:
   - `Navigator.pop(context, {'settings': _settings, 'useServer': _useServer});`
   - Nó đóng màn hình và trả ngược cục dữ liệu Cấu hình này về cho `CreatorScreen` (Bước 2) để tiếp tục chuyền xuống cho màn hình Preview chạy AI thực sự.

---
**Tóm tắt bước này:**
Người dùng không xử lý ảnh ở đây. Họ chỉ tạo ra một bộ "công thức" (Settings) và chọn "cỗ máy" (Server hay Local) để chuẩn bị cho quá trình biến đổi ảnh ở bước tiếp theo.
