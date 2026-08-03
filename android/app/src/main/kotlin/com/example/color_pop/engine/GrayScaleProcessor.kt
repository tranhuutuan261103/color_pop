// ==================================================
// Nhóm 2: Các thuật toán xử lý pixel Pixel cốt lõi 
// ==================================================

// 1. File GrayScaleProcessor.kt (Bộ Xử Lý Màu Xám)
/* Vai trò: Chuyển đổi mảng màu ARGB thành dải màu xám (Grayscale).
Tại sao: Thuật toán dò viền (Edge Detection) chỉ hoạt động chính xác dựa trên 
cường độ sáng (Luminance), không quan tâm đến màu sắc. */

package com.example.color_pop.engine

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

object GrayScaleProcessor {
    /**
     * Chuyển đổi mảng pixel thành trắng đen.
     * Xử lý in-place (trực tiếp trên mảng gốc) để không tốn thêm RAM khởi tạo mảng mới.
     * Thuật toán được tối ưu hóa cực đại để chạy trên hàng triệu pixel mà không gây giật lag.
     */
    
    suspend fun processInPlace(pixels: IntArray) = withContext(Dispatchers.Default) {
    // Luồng Dispatchers.Default chuyên trị các phép tính toán học nặng (CPU-bound)
        for (i in pixels.indices) {
            val p = pixels[i]
            
            // 1. TÁCH KÊNH MÀU
            // Pixel là 1 số 32-bit cấu trúc ARGB. Dùng bitwise shift (shr - shift right) để đẩy màu về cuối 
            // và mask (and 0xff) để lấy ra chính xác giá trị 0-255 của từng kênh.
            // Cấu trúc của 1 pixel ARGB: 0xAARRGGBB (Alpha, Red, Green, Blue) (AAAAAAAA_RRRRRRRR_GGGGGGGG_BBBBBBBB)
            val a = (p shr 24) and 0xff // shr 24: Dịch toàn bộ dãy bit sang phải 24 bước để đẩy cụm AAAAAAAA xuống cuối
            val r = (p shr 16) and 0xff 
            val g = (p shr 8) and 0xff  
            val b = p and 0xff
            // and 0xff: Dùng mặt nạ 11111111 (tương đương 0xff trong hệ Hex) để lọc và chỉ giữ lại 8 bit cuối cùng, loại bỏ phần dư thừa.
            
            // 2. TÍNH TOÁN ĐỘ SÁNG (LUMA) BẰNG SỐ NGUYÊN (FAST MATH)
            // Thay vì dùng Float: Y = R*0.299 + G*0.587 + B*0.114 (Rất chậm).
            // Ta nhân hệ số với 256 để biến thành số nguyên (77, 150, 29), cộng lại, 
            // sau đó chia lại cho 256 bằng toán tử dịch phải 8 bit (shr 8).
            // Tốc độ thực thi toán tử bitwise này nhanh hơn phép nhân/chia Float rất nhiều.
            // Công thức Luma chuẩn: Y = 0.299R + 0.587G + 0.114B
            // Tối ưu hóa số nguyên: (R*77 + G*150 + B*29) >> 8 (nhanh hơn phép nhân số thực Float)
            val gray = (r * 77 + g * 150 + b * 29) shr 8
            // Nhân các hệ số đó với 256 (2^8) và dịch phải 8 bit để chia lại cho 256 (shr 8), tránh dùng số thực Float.
            
            // 3. ĐÓNG GÓI LẠI THÀNH MÃ MÀU MỚI
            // Đẩy Alpha, Red, Green, Blue về lại đúng vị trí 32-bit của nó bằng (shl - shift left).
            // Gán R, G, B đều bằng giá trị 'gray' để ra ảnh trắng đen.
            // Dùng (or) để gộp chúng lại, sau đó gán đè vào vị trí cũ.
            pixels[i] = (a shl 24) or (gray shl 16) or (gray shl 8) or gray
        }
    }
}