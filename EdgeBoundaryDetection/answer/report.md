# Báo cáo Phân tích Dữ liệu và Thiết kế Mô hình HED

Dưới đây là tài liệu lý thuyết, câu hỏi, phân tích thống kê và giải thích chi tiết lý do tại sao chúng ta thiết kế hệ thống như hiện tại, trước khi bước vào quá trình huấn luyện mô hình (Training). Việc hiểu rõ dữ liệu là bước quan trọng nhất để tối ưu hóa quá trình học sâu (Deep Learning).

---

## 1. Thống kê và Phân tích Mức độ Chênh lệch Dữ liệu (Class Imbalance)

### Mục tiêu: 
Hiểu rõ đặc trưng phân bố của các pixel trong tập dữ liệu BSDS500. Trong bài toán tách viền (Edge Detection), chúng ta thực chất đang giải quyết bài toán phân loại nhị phân trên từng pixel (Binary Pixel Classification), với 2 class là: **Viền (Edge - 1)** và **Nền (Background - 0)**.

### Kết quả phân tích (Từ script `analyze_data.py`):
Trên toàn bộ tập huấn luyện `train` của BSDS500:
- **Tổng số pixel:** `30,880,200`
- **Số pixel viền (Edge):** `1,972,517` (chiếm **6.39%**)
- **Số pixel nền (Background):** `28,907,683` (chiếm **93.61%**)

### Đánh giá và Ứng dụng vào Mô hình:
Sự chênh lệch giữa class 0 và class 1 là cực kỳ lớn (Tỉ lệ ~ **15:1**). 
> [!WARNING]
> **Hậu quả nếu dùng Loss thông thường:** Nếu dùng hàm Binary Cross Entropy (BCE) mặc định, mô hình sẽ bị "lười biếng". Nó nhận ra rằng nếu nó đoán **toàn bộ bức ảnh là nền (màu đen)** thì độ chính xác (accuracy) của nó đã tự động đạt **93.61%**. Kết quả là mạng U-Net cũ của bạn trả về một bức ảnh đen thui, không tìm được đường viền nào.

> [!TIP]
> **Giải pháp trong kiến trúc hiện tại (Class-Balanced Loss):** 
> Để bắt mô hình phải chú ý vào các nét vẽ mỏng manh, trong file `src/step04_loss.py`, tôi đã triển khai kỹ thuật nhân trọng số (weighted loss). Cụ thể, mỗi pixel viền đoán sai sẽ bị phạt nặng gấp **~15 lần** so với một pixel nền đoán sai. Công thức: `pos_weight = Số pixel nền / Số pixel viền`.

---

## 2. Trực quan hóa và Lý thuyết Trích xuất Đặc trưng (Feature Extraction)

Để có cái nhìn trực quan, tôi đã chạy và so sánh thuật toán trích xuất đặc trưng truyền thống (Canny Edge Detector) với chuẩn do con người gán (Ground Truth).

![Canny Comparison](file:///d:/fau/EdgeBoundaryDetection/answer/comparison.png)
*(Nếu hình ảnh không hiển thị, bạn có thể xem trực tiếp tại `d:/fau/EdgeBoundaryDetection/answer/comparison.png`)*

### Phân tích biểu đồ:
- **Thuật toán Canny (Bên phải):** Canny dựa vào sự thay đổi độ sáng (gradient) của ảnh. Nó hoạt động rập khuôn dựa trên toán học (Low-level features). Kết quả là nó sẽ lấy ra **tất cả** các chi tiết nhiễu, lông đuôi, kết cấu lá cây, v.v. Nó không phân biệt được đâu là đường viền chính của chủ thể (object contour) và đâu là kết cấu bề mặt (texture).
- **Ground Truth (Ở giữa):** Con người chỉ đánh dấu đường viền phân chia các vật thể rõ ràng, loại bỏ những chi tiết rườm rà không cần thiết. Đây là "ngữ nghĩa" (semantic meaning) mà ta muốn mô hình học được.

### Tại sao dùng HED (Holistically-Nested Edge Detection)?
Mô hình HED (được viết trong `src/step03_model.py`) giải quyết xuất sắc bài toán này nhờ 2 yếu tố:
1. **Trích xuất đặc trưng đa phân cấp (Multi-scale Feature Extraction):** HED sử dụng 5 block tích chập (convolution) từ VGG16. Các block đầu tiên (side 1, 2) trích xuất các đặc trưng cấp thấp (cạnh, góc giống Canny). Các block sâu hơn (side 3, 4, 5) sẽ bao quát ngữ cảnh rộng hơn (đặc trưng cấp cao), giúp nó hiểu được đâu là đường nét tạo nên hình khối con vật, đâu chỉ là kết cấu lông.
2. **Lớp Gộp (Fusion Layer):** Kết hợp cả 5 cấp độ đặc trưng này lại để đưa ra một quyết định cuối cùng, giúp nét vẽ vừa sắc sảo (nhờ block đầu), vừa lọc sạch nhiễu (nhờ block cuối).

---

## 3. Tổng kết 

Bằng việc (1) Sử dụng HED để trích xuất cả đặc trưng chi tiết và ngữ nghĩa, kết hợp với (2) Hàm Class-balanced Loss để trị dứt điểm chứng thiên lệch dữ liệu, mô hình HED hiện tại được tối ưu hóa ở mức cao nhất cho ứng dụng tách viền trước khi tô màu của bạn.

Mọi lỗi về môi trường `Modal` cũng đã được khắc phục hoàn toàn bằng phương thức `add_local_dir`. 

Bạn có thể tiến hành huấn luyện (train) mô hình một cách an tâm bằng lệnh:
```bash
modal run step00_main.py
```
