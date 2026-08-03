// ==================================================
// Nhóm 2: Các thuật toán xử lý pixel Pixel cốt lõi 
// ==================================================

// 5. File OutlineMaskBuilder.kt
/* Vai trò: Kết hợp toàn bộ các thuật toán bên trên thành một Pipeline hoàn chỉnh. 
File này sẽ nhận Bitmap, xử lý và tạo ra mảng ByteArray mà Flutter yêu cầu. 
(1: Viền đen cần giữ lại, 0: Khoảng trống để tô). 
File này mô phỏng lại cách mắt người và não bộ nhận diện một đồ vật: 
Bỏ qua màu sắc -> Bỏ qua các chi tiết vụn vặt -> Tìm kiếm sự tương phản -> Vẽ ra đường viền. */

package com.example.color_pop.engine

import android.graphics.Bitmap
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * [OutlineMaskBuilder]
 * Xây dựng mặt nạ đường viền (Outline Mask) dùng cho Layer vẽ của Flutter.
 * Áp dụng mô hình Computer Vision Pipeline kinh điển.
 */
object OutlineMaskBuilder {
    
    /**
     * Pipeline xử lý ảnh từ màu -> Viền.
     * @param threshold Giá trị ngưỡng (0-255). Pixel viền có cường độ lớn hơn threshold sẽ được coi là nét vẽ vững chắc.
     */
    suspend fun build(bitmap: Bitmap, threshold: Int = 120, applyBlur: Boolean = false): ByteArray? {
        // Sử dụng luồng tính toán tối đa sức mạnh CPU
        return withContext(Dispatchers.Default) {
            try {
                val width = bitmap.width
                val height = bitmap.height
                val size = width * height

                // 1. LẤY DATA THÔ: Trích xuất pixels thô (Lấy từ Object Pool để tránh cấp phát RAM mới)
                val pixels = BitmapCache.getPixelsFromBitmap(bitmap)

                // 2. CHUYỂN XÁM: Loại bỏ màu sắc, chỉ giữ lại cường độ sáng
                /* Bước 2 (Grayscale): Thuật toán tìm viền (Sobel) hoạt động dựa trên sự chênh lệch độ sáng 
                (intensity), chứ không quan tâm đến màu xanh đỏ tím vàng. Việc chuyển xám là bắt buộc. */
                GrayScaleProcessor.processInPlace(pixels)

                // 3. KHỬ NHIỄU: "Chà phẳng" ảnh để loại bỏ các hạt noise, giúp bộ dò viền không bị nhận diện sai các chi tiết rác.
                /* Bước 3 (Gaussian Blur - Làm mờ): Ảnh chụp từ camera thường bị "nhiễu hạt" (noise). 
                Nếu không làm mờ nhẹ, thuật toán tìm viền sẽ tưởng những hạt nhiễu li ti đó là đường viền và 
                vẽ ra một mớ hỗn độn. Blur giúp "chà phẳng" bức ảnh, chỉ giữ lại những đường nét chính. */
                if (applyBlur) {
                    GaussianBlur.fastBlur(pixels, width, height, radius = 1)
                }

                // 4. DÒ VIỀN (Sobel): Phát hiện cạnh bằng Sobel Operator (Kết quả: Cạnh sẽ là màu sáng/trắng trên nền đen)
                /* Bước 4 (Sobel Operator): Đây là thuật toán kinh điển trong xử lý ảnh. Nó quét qua bức ảnh 
                để tìm những nơi có sự thay đổi độ sáng đột ngột (ví dụ: một vùng áo trắng nằm cạnh một mảng tóc đen). 
                Kết quả của hàm này biến bức ảnh thành một màn đêm đen tuyền, trên đó các đường viền sẽ phát sáng (màu trắng). */
                EdgeDetector.applySobel(pixels, width, height)

                // 5. CHỐNG TRÀN MÀU (Morphology Dilation): 
                // Làm cho các đường nét trắng phình to ra một chút để vá kín các điểm đứt gãy li ti.
                // Đảm bảo công cụ Paint Bucket của người dùng không bị tràn màu ra ngoài.
                /* Bước 5 (Dilation - Làm dày nét): Tại sao phải có bước này? Vì ứng dụng của bạn là tô màu (Flood Fill / Paint Bucket). 
                Nếu đường viền do Sobel tạo ra quá mỏng và vô tình bị đứt 1 pixel, lúc người dùng đổ màu, màu sẽ "tràn" (leak) ra ngoài mảng khác. 
                Phép toán dilate sẽ làm cho các nét viền trắng phình to ra, bít kín mọi lỗ hổng. */
                Morphology.dilate(pixels, width, height)

                // 6. NHỊ PHÂN HÓA VÀ NÉN DỮ LIỆU
                // Tạo mảng Byte (1 Byte/pixel) thay vì Int (4 Byte/pixel) để tiết kiệm 75% RAM 
                // khi truyền qua MethodChannel về lại Flutter.
                // Trả về ByteArray vì Flutter đang chờ mảng Byte (1 Byte/pixel) tiết kiệm RAM hơn IntArray.
                /* Bước 6 (Thresholding): Các đường viền lúc này có độ sáng khác nhau (từ xám mờ mờ đến trắng bóc, giá trị từ 0-255). 
                Biến threshold = 120 đóng vai trò làm "Trạm kiểm soát": Những pixel nào sáng từ 120 trở lên mới được công nhận là Nét vẽ chắc chắn (mask = 1), 
                dưới 120 bị coi là rác và cho thành vùng trống (mask = 0). */
                val mask = ByteArray(size)
                for (i in 0 until size) {
                    // Viền lúc này là vùng sáng (do Sobel tạo ra). 
                    val edgeStrength = pixels[i] and 0xFF // Lấy cường độ sáng của pixel hiện tại (0 -> 255)
                    
                    // Nếu cường độ lớn hơn ngưỡng cho phép, chốt nó là Viền (1), ngược lại là Rỗng (0)
                    if (edgeStrength >= threshold) {
                        mask[i] = 1 // Điểm này là Nét vẽ (Outline)
                    } else {
                        mask[i] = 0 // Điểm này là vùng trống để tô màu
                    }
                }

                // 7. TÁI CHẾ BỘ NHỚ
                // Trả mảng mảng pixels khổng lồ này về Object Pool để tái sử dụng cho ảnh sau,
                // ngăn chặn hệ thống Garbage Collector làm giật lag app.
                // Nhả mảng pixel thô về Pool
                /* BitmapCache.releaseIntArray(pixels): Khác với Java/Kotlin thông thường phó mặc cho 
                Garbage Collector đi dọn rác, mảng pixels này quá lớn (có thể lên tới hàng chục triệu phần tử) */
                BitmapCache.releaseIntArray(pixels)

                mask // Trả mảng Byte nhị phân về cho hàm gọi
            } catch (e: Exception) {
                e.printStackTrace()
                null
            }
        }
    }
}