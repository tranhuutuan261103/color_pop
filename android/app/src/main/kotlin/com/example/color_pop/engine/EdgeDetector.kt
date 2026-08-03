// ==================================================
// Nhóm 2: Các thuật toán xử lý pixel Pixel cốt lõi 
// ==================================================

// 3. File EdgeDetector.kt (Sobel Operator)
/* Vai trò: Tìm ra các nét vẽ (Đường viền) của bức tranh.
Thuật toán Sobel: Nó tính toán sự thay đổi cường độ sáng theo trục X và trục Y. 
Nơi nào cường độ sáng thay đổi đột ngột (ví dụ từ giấy trắng sang mực đen), nơi đó là đường viền. */


package com.example.color_pop.engine

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlin.math.abs

object EdgeDetector {
    /**
     * Dò viền bằng thuật toán Sobel Operator.
     * Ảnh đầu vào PHẢI là ảnh Grayscale (đã được xử lý ở bước trước).
     */
    suspend fun applySobel(pixels: IntArray, width: Int, height: Int) = withContext(Dispatchers.Default) {
        val size = width * height
        // [QUẢN LÝ BỘ NHỚ]: Tiếp tục mượn mảng tạm từ Pool để tránh cấp phát RAM
        val buffer = BitmapCache.obtainIntArray(size)

        // Ma trận Sobel X và Y
        // Gx = [-1, 0, 1]  Gy = [-1,-2,-1]
        //      [-2, 0, 2]       [ 0, 0, 0]
        //      [-1, 0, 1]       [ 1, 2, 1]

        // Ma trận Sobel X (Dò sự thay đổi cường độ sáng theo chiều ngang)
        // Gx = [-1, 0, 1] 
        //      [-2, 0, 2] 
        //      [-1, 0, 1] 
        
        // Ma trận Sobel Y (Dò sự thay đổi cường độ sáng theo chiều dọc)
        // Gy = [-1,-2,-1]
        //      [ 0, 0, 0]
        //      [ 1, 2, 1]

        // [TỐI ƯU HIỆU NĂNG 1]: Thu hẹp viền quét vào trong 1 pixel (1 until bounds - 1)
        // Điều này giúp loại bỏ 100% các câu lệnh IF kiểm tra viền (bounds checking) 
        // bên trong vòng lặp, giúp CPU chạy luồng lệnh mượt mà không bị ngắt quãng.
        for (y in 1 until height - 1) {
            val offset = y * width
            for (x in 1 until width - 1) {
                val i = offset + x
                
                // Lấy cường độ sáng của 8 pixel xung quanh hạt nhân (kernel) 3x3.
                // Do ảnh đã là Grayscale (R=G=B) nên ta tiếp tục dùng mẹo 'and 0xFF' 
                // để rút trích nhanh 1 kênh màu thay vì phải bóc tách đầy đủ.
                val p00 = pixels[i - width - 1] and 0xFF
                val p01 = pixels[i - width] and 0xFF
                val p02 = pixels[i - width + 1] and 0xFF
                val p10 = pixels[i - 1] and 0xFF
                val p12 = pixels[i + 1] and 0xFF
                val p20 = pixels[i + width - 1] and 0xFF
                val p21 = pixels[i + width] and 0xFF
                val p22 = pixels[i + width + 1] and 0xFF

                // Tính Gradient trục X và Y
                // Nhân chập (Convolution) với ma trận Gx và Gy
                // Các điểm số 2 và -2 là để tạo trọng số tập trung vào điểm ở giữa hơn.
                val gx = (p02 + 2 * p12 + p22) - (p00 + 2 * p10 + p20)
                val gy = (p20 + 2 * p21 + p22) - (p00 + 2 * p01 + p02)

                // [TỐI ƯU HIỆU NĂNG 2]: Thay thế căn bậc 2 (Math.sqrt) đắt đỏ bằng trị tuyệt đối (Math.abs)
                // Đánh đổi một chút xíu độ chính xác để đổi lấy tốc độ render tăng hàng chục lần.
                var magnitude = abs(gx) + abs(gy)
                if (magnitude > 255) magnitude = 255 // Khóa giá trị lại ở mức tối đa là 255 (Màu trắng sáng nhất)

                // Lưu lại kết quả vào buffer: 
                // Biến những nơi chênh lệch ánh sáng cao thành viền Trắng (magnitude lớn),
                // Những nơi màu phẳng thành nền Đen (magnitude = 0).
                buffer[i] = (0xFF shl 24) or (magnitude shl 16) or (magnitude shl 8) or magnitude
            }
        }

        // [TỐI ƯU HIỆU NĂNG 3]: Dùng System.arraycopy (Memcpy ở tầng C/C++) 
        // để đổ ngược data từ buffer vào mảng gốc với tốc độ phần cứng, 
        // thay vì dùng vòng lặp for thông thường.
        System.arraycopy(buffer, 0, pixels, 0, size)
        BitmapCache.releaseIntArray(buffer) // Trả buffer về kho
    }
}