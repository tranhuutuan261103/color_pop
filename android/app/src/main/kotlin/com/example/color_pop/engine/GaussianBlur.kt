// ==================================================
// Nhóm 2: Các thuật toán xử lý pixel Pixel cốt lõi 
// ==================================================

// 2. File GaussianBlur.kt (Fast Box Blur)
/* Vai trò: Khử nhiễu (noise) cho ảnh. Nếu ảnh chụp bằng camera có hạt nhiễu (noise), 
thuật toán dò viền sẽ nhận nhầm đó là đường nét.
Bí kíp tối ưu: True Gaussian Blur dùng ma trận 2D rất nặng. Trong công nghiệp, người ta dùng Separable Box Blur 
(làm mờ theo chiều ngang, rồi làm mờ theo chiều dọc). */
package com.example.color_pop.engine

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlin.math.max
import kotlin.math.min

object GaussianBlur {
    
    /**
     * Làm mờ ảnh sử dụng thuật toán Separable Box Blur.
     * Thuật toán này có độ phức tạp là O(N) thay vì O(N^2) như Gaussian Blur truyền thống.
     */
    /**
     * Thực hiện Box Blur hai chiều bằng hai lượt:
     * - Horizontal Blur: pixels -> buffer
     * - Vertical Blur: buffer -> pixels
     *
     * Sử dụng buffer trung gian để tránh read-after-write và tái sử dụng bộ nhớ
     * thông qua BitmapCache.
     */ 
    suspend fun fastBlur(pixels: IntArray, width: Int, height: Int, radius: Int) = withContext(Dispatchers.Default) {
        if (radius < 1) return@withContext
        
        val size = width * height
        // [QUẢN LÝ BỘ NHỚ]: Mượn mảng tạm từ Object Pool thay vì khởi tạo mới.
        // Ngăn chặn Garbage Collector phải dọn rác 50MB gây khựng UI (Jank).
        val buffer = BitmapCache.obtainIntArray(size)

        // Bước 1: Quét dọc theo từng hàng ngang, làm mờ ngang (Horizontal Blur) và lưu kết quả vào Buffer 
        boxBlurHorizontal(pixels, buffer, width, height, radius)
        
        // Bước 2: Đọc dữ liệu từ Buffer, làm mờ dọc (Vertical Blur) và ghi đè thẳng lại vào mảng gốc 
        boxBlurVertical(buffer, pixels, width, height, radius)

        // [QUẢN LÝ BỘ NHỚ]: Trả "tờ nháp" lại cho Pool để các tiến trình khác xài.
        BitmapCache.releaseIntArray(buffer)
    }

    // Hàm làm mờ theo chiều ngang (Horizontal Box Blur)
    private fun boxBlurHorizontal(src: IntArray, dest: IntArray, w: Int, h: Int, r: Int) {
        // Duyệt từng hàng ngang (y)
        for (y in 0 until h) {
            val offset = y * w
            // Duyệt từng pixel (x) trong hàng ngang đó
            for (x in 0 until w) {
                var sum = 0
                var count = 0

                // Thu thập các pixel xung quanh theo chiều NGANG (từ x - r đến x + r)
                // Dùng max/min để đảm bảo không lấy viền tràn ra ngoài bức ảnh (IndexOutOfBounds)
                for (kx in max(0, x - r)..min(w - 1, x + r)) {
                    val p = src[offset + kx]
                    sum += p and 0xFF // Vì ảnh đã grayscale, chỉ cần lấy 1 kênh (Blue) làm đại diện
                    count++
                }
                val avg = sum / count // Tính trung bình cộng độ sáng

                // Đóng gói lại thành mã 32-bit (ARGB) với Alpha = 255 (0xFF), và R=G=B=avg
                dest[offset + x] = (0xFF shl 24) or (avg shl 16) or (avg shl 8) or avg
            }
        }
    }

    // Hàm làm mờ theo chiều dọc (Vertical Box Blur)
    private fun boxBlurVertical(src: IntArray, dest: IntArray, w: Int, h: Int, r: Int) {
        // Duyệt từng cột dọc (x)
        for (x in 0 until w) {
            // Duyệt từng pixel (y) trong cột đó
            for (y in 0 until h) {
                var sum = 0
                var count = 0

                // Thu thập các pixel xung quanh theo chiều DỌC (từ y - r đến y + r)
                for (ky in max(0, y - r)..min(h - 1, y + r)) {
                    // Công thức tính index 1D cho tọa độ 2D là: Y * Width + X
                    val p = src[ky * w + x]
                    sum += p and 0xFF
                    count++
                }
                val avg = sum / count // Tính trung bình cộng độ sáng

                // Đóng gói lại thành mã 32-bit (ARGB) với Alpha = 255 (0xFF), và R=G=B=avg
                dest[y * w + x] = (0xFF shl 24) or (avg shl 16) or (avg shl 8) or avg
            }
        }
    }
}