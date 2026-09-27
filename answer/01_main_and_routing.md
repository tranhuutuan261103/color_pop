# 01. Điểm khởi đầu và Điều hướng (Main & Routing)

Luồng xử lý tách viền ảnh AI bắt đầu từ việc khởi chạy ứng dụng và định nghĩa các tuyến đường điều hướng (routing). Quá trình này được quản lý bởi các file cốt lõi sau:

## 1. `lib/main.dart`
Đây là điểm Entry Point của toàn bộ ứng dụng Flutter. 
- Gọi `WidgetsFlutterBinding.ensureInitialized()` để khởi tạo cầu nối giữa Flutter và Native code.
- Chạy `runApp(MyApp())` để khởi động ứng dụng.

## 2. `lib/app/app.dart`
Thiết lập cấu hình giao diện `MaterialApp` chính, bao gồm Theme (sáng/tối) và hệ thống routing:
- `initialRoute: AppRouter.homeRoute` (khởi đầu ở trang chủ).
- `onGenerateRoute: AppRouter.generateRoute` (quản lý cách chuyển trang và truyền tham số).

## 3. `lib/app/app_router.dart`
File cực kỳ quan trọng đóng vai trò "người chỉ đường" cho toàn bộ luồng Creator. Các route chính liên quan đến chức năng tách ảnh AI bao gồm:

* **`/edge-settings`** (`EdgeSettingsRoute`): Điều hướng đến màn hình `EdgeSettingsScreen` để thiết lập các thông số (Threshold, Blur, Server/Local) trước khi chạy AI.
* **`/edge-preview`** (`EdgePreviewRoute`): Điều hướng đến `EdgePreviewScreen`. Nhận tham số là `imageBytes` (dữ liệu ảnh thô), đường dẫn ảnh, cấu hình settings từ bước trước. Đây là nơi AI chạy và hiển thị kết quả tách viền (lineart).
* **`/workspace`** (`WorkspaceRoute`): Điều hướng đến `WorkspaceScreen` (Màn hình tô màu chính). 
  - Trong luồng AI, route này nhận tham số `edgeBytes` (kết quả ảnh PNG viền đen trắng đã được xử lý hoàn chỉnh từ AI).

---
**Tóm tắt bước này:** 
Hệ thống router đã sẵn sàng. Khi người dùng bấm vào chức năng tạo ảnh, ứng dụng sẽ lần lượt đi qua các route: `Home` -> Chọn ảnh -> `Edge Settings` -> `Edge Preview` (AI xử lý) -> `Workspace` (Tô màu).
