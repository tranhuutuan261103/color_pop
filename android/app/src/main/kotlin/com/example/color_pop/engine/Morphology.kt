// ==================================================
// Nhóm 2: Các thuật toán xử lý pixel Pixel cốt lõi 
// ==================================================

// 4. File Morphology.kt (Dilation - Làm dày nét)
/* Vai trò: Khi tìm viền, nét vẽ đôi khi bị đứt đoạn li ti. 
"Dilation" (Nở ra) giúp làm các nét viền này bự lên 1 chút, nối liền các chỗ đứt, 
giúp cho thuật toán Tô màu (Flood Fill) ở phần sau không bị tràn mực (leak) ra ngoài hình. */

package com.example.color_pop.engine

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlin.math.max

object Morphology {
    /**
     * Thuật toán Dilation (Phép Nở). 
     * Tác dụng: Làm phình to/dày thêm các đường viền sáng màu, giúp vá kín các đứt gãy li ti.
     * Đây là lớp lá chắn "Anti-Leak" (Chống tràn) hoàn hảo cho công cụ Đổ màu (Flood Fill).
     */
    suspend fun dilate(pixels: IntArray, width: Int, height: Int) = withContext(Dispatchers.Default) {
        val size = width * height

        // [QUẢN LÝ BỘ NHỚ]: Mượn mảng nháp từ kho chứa để tránh cấp phát động gây giật lag
        val buffer = BitmapCache.obtainIntArray(size)

        // [TỐI ƯU TỐC ĐỘ]: Bỏ qua 1 pixel ở 4 cạnh viền ngoài cùng.
        // Điều này giúp vòng lặp bên trong (dx, dy) yên tâm duyệt 3x3 mà không sợ bị lố (Crash app).
        // CPU chạy băng băng vì không bị vướng các câu lệnh rẽ nhánh 'IF' kiểm tra biên.
        for (y in 1 until height - 1) {
            val offset = y * width
            for (x in 1 until width - 1) {
                val i = offset + x
                
                // Thuật toán MAX POOLING (Lọc giá trị lớn nhất trong cửa sổ 3x3)
                // Tìm pixel sáng nhất (nhân viền rõ nhất) trong phạm vi 3x3
                var maxVal = 0
                
                // Duyệt qua 9 pixel xung quanh (bao gồm cả chính nó)
                for (dy in -1..1) {
                    for (dx in -1..1) {
                        // Lấy cường độ sáng (chỉ cần lấy kênh Blue bằng 'and 0xFF' vì ảnh là Grayscale)
                        val v = pixels[i + dy * width + dx] and 0xFF
                        
                        // Cập nhật giá trị sáng nhất
                        // Thay vì dùng Math.max() tốn chi phí gọi hàm, tác giả dùng 'if' trực tiếp cho lẹ
                        if (v > maxVal) maxVal = v
                    }
                }
                
                // Gán giá trị sáng nhất vừa tìm được cho pixel trung tâm (i).
                // Hiệu ứng: Các pixel sáng (viền) sẽ "lan tỏa" và nuốt chửng các pixel tối (khe hở).
                buffer[i] = (0xFF shl 24) or (maxVal shl 16) or (maxVal shl 8) or maxVal
            }
        }

        // Ốp kết quả từ buffer về lại mảng ảnh gốc bằng lệnh copy tốc độ cao của Native OS
        System.arraycopy(buffer, 0, pixels, 0, size)

        // Trả buffer về kho cho các tiến trình khác xài
        BitmapCache.releaseIntArray(buffer)
    }
}