# 02. Giao diện Creator và Mở Thư viện (Creator Screen)

## File: `lib/features/creator/view/creator_screen.dart`

Đây là màn hình UI nơi người dùng chọn tính năng "AI Model" (AI Photo to Draw) để biến bức ảnh chụp trong điện thoại thành một bức tranh tô màu.

### Quá trình hoạt động:

1. **Hiển thị thẻ chức năng:** Màn hình vẽ ra UI với nút **"AI Model"**. Khi người dùng nhấn nút này, hàm `_pickImageAndNavigate('ai')` sẽ được kích hoạt.
2. **Chọn ảnh từ thiết bị:**
   - Sử dụng thư viện `ImagePicker`: `picker.pickImage(source: ImageSource.gallery)`.
   - Ứng dụng mở thư viện ảnh trên điện thoại để người dùng chọn một bức ảnh.
3. **Đọc dữ liệu ảnh gốc:**
   - Bức ảnh được chọn (XFile) sẽ được đọc trực tiếp thành mảng byte (`bytes = await image.readAsBytes()`).
4. **Bắt đầu chuỗi điều hướng cho AI:**
   - **Bước 1:** Đẩy sang màn hình thiết lập thông số `/edge-settings`. 
     - Lệnh: `await Navigator.pushNamed(context, '/edge-settings')`.
     - Ứng dụng chờ đợi người dùng cấu hình xong thông số và chọn chế độ (Server/Local).
   - **Bước 2:** Sau khi nhận lại cấu hình (`settingsResult`), ứng dụng tiếp tục đẩy sang màn hình `/edge-preview`.
     - Chuyển tiếp các tham số cực kỳ quan trọng vào Arguments: `imageBytes` (dữ liệu ảnh gốc), `imagePath`, `settings` (thông số đã cấu hình) và `useServer` (cờ chạy AI trên máy chủ hay thiết bị).
   - **Bước 3:** Tại `/edge-preview`, nếu người dùng hài lòng với kết quả AI và bấm "Apply", ứng dụng nhận lại kết quả `result` (chứa `edgeBytes` - ảnh viền đã tách xong).
   - **Bước 4:** Đẩy toàn bộ dữ liệu cuối cùng sang không gian vẽ `/workspace` để người dùng bắt đầu tô màu.

---
**Tóm tắt bước này:**
`CreatorScreen` đóng vai trò là nhạc trưởng điều phối toàn bộ chuỗi sự kiện: từ mở bộ sưu tập lấy ảnh gốc -> nạp ảnh -> gọi màn setting -> gọi màn preview AI -> nhận kết quả hoàn chỉnh -> mở bàn vẽ Workspace.
