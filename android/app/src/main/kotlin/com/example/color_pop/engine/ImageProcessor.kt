// ==================================================================
// Nhóm 3: Quản lý điều phối I/O giữa Flutter và Native (Kotlin/Java)
// ==================================================================

// 2. File ImageProcessor.kt (Người Điều Phối Lõi)
/* Vai trò: Cung cấp API cấp cao (Facade). Flutter không cần biết bên trong có bao nhiêu thuật toán, 
nó chỉ gọi qua ImageProcessor. */

package com.example.color_pop.engine
import android.graphics.Bitmap
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * [ImageProcessor] (Facade Pattern)
 * Controller chính điều phối các Engine con.
 * Không chứa logic toán học, chỉ làm nhiệm vụ quản lý luồng dữ liệu (Load -> Process -> Save)
 * và tối ưu hóa bộ nhớ RAM.
 */
object ImageProcessor {
    // LƯU TRỮ RAM (STATE)
    private var activeBitmap: Bitmap? = null
    private var outlineMask: ByteArray? = null
    var activeWidth = 0
    var activeHeight = 0

    // 1. Load ảnh vào RAM (Dùng khi mở Project cũ hoặc load ảnh mới)
    suspend fun loadProjectToRAM(path: String): ByteArray? = withContext(Dispatchers.IO) {
        activeBitmap?.recycle()
        activeBitmap = BitmapLoader.load(path)
        if (activeBitmap == null) return@withContext null
        
        activeWidth = activeBitmap!!.width
        activeHeight = activeBitmap!!.height

        // Tự động tạo Mask viền đen lưu lại để dùng cho Smart Brush
        outlineMask = OutlineMaskBuilder.build(activeBitmap!!, 120, false)

        // Trả về ByteArray (chuẩn PNG/JPEG) cho Flutter hiển thị
        return@withContext getEncodedBytes()
    }

    // 2. Chuyển đổi đen trắng & Trả về thông tin đầy đủ cho Flutter
    // Sử dụng 'suspend' để chạy bất đồng bộ, không làm đơ giao diện Flutter.
    suspend fun processGrayscale(inputPath: String, outputPath: String): Map<String, Any>? {
        // Tải ảnh an toàn qua BitmapLoader, nếu lỗi (file hỏng, hết RAM) trả về null để báo lỗi lên UI
        val bitmap = BitmapLoader.load(inputPath) ?: return null
        val width = bitmap.width
        val height = bitmap.height
        
        // Rút toàn bộ điểm ảnh (pixels) ra một mảng Int Array độc lập
        val pixels = BitmapCache.getPixelsFromBitmap(bitmap)
        bitmap.recycle() // Xóa bitmap ngay lập tức
        // Từ lúc này, ta chỉ thao tác với mảng 'pixels'.

        // Xử lý trắng đen trực tiếp trên mảng gốc (In-place) để không tốn thêm bộ nhớ
        GrayScaleProcessor.processInPlace(pixels)
        
        // Lưu mảng pixel đã xử lý xuống file ở ổ cứng
        val saved = BitmapSaver.saveFromPixels(pixels, width, height, outputPath)
        if (!saved) return null

        // Trả về Map chứa đường dẫn và kích thước để Flutter không phải tự đọc lại file
        return mapOf(
            "path" to outputPath,
            "width" to width,
            "height" to height
        )
    }

    // 3. Lấy thông tin kích thước ảnh (Cho trường hợp mở lại Project cũ)
    // Ép chạy ngầm ở luồng I/O (chuyên đọc ghi file) để tối ưu
    suspend fun getImageInfo(path: String): Map<String, Int>? = withContext(Dispatchers.IO) {
        try {
            // [TỐI ƯU]: Chỉ đọc Header (EXIF) của file để lấy kích thước thay vì load cả bức ảnh.
            // Tốc độ phản hồi cực nhanh (~0.001s) và không tốn RAM.
            val bounds = ImageScaler.getImageBounds(path)
            mapOf(
                "width" to bounds.first,
                "height" to bounds.second
            )
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    // 4. Trích xuất mảng đường viền (Outline Mask)
    suspend fun buildOutlineMask(inputPath: String, threshold: Int): ByteArray? {
        // Load ảnh cần lấy viền
        val bitmap = BitmapLoader.load(inputPath) ?: return null
        // Giao việc xử lý cho Computer Vision
        val mask = OutlineMaskBuilder.build(bitmap, threshold, applyBlur = true)
        bitmap.recycle() // Thu dọn RAM ngay lập tức
        return mask
    }

    // Quản lý layer ảo dưới Native (Giả định bạn có 1 mảng lưu ảnh đang vẽ)
    var currentActiveLayerPixels: IntArray? = null
    var currentLayerWidth: Int = 0
    var currentLayerHeight: Int = 0

    // Khởi tạo Layer (Gọi khi người dùng vừa load ảnh xong)
    fun initActiveLayer(pixels: IntArray, w: Int, h: Int) {
        currentActiveLayerPixels = pixels
        currentLayerWidth = w
        currentLayerHeight = h
    }

    // 5. Vẽ nét cọ (Brush Stroke) hoặc Cục tẩy (Eraser) lên lớp ảnh đang thao tác.
    suspend fun applyBrushStroke(points: DoubleArray, color: Int, radius: Float, isEraser: Boolean): Boolean {
        val pixels = currentActiveLayerPixels ?: return false
        BrushEngine.paintStroke(pixels, currentLayerWidth, currentLayerHeight, points, color, radius, isEraser)
        return true
    }
    
    // 6. Vẽ nét cọ thông minh (Smart Brush) với thuật toán chọn lọc vùng an toàn
    suspend fun applySmartBrush(
        points: DoubleArray, color: Int, radius: Float, startX: Int, startY: Int, isEraser: Boolean
    ): ByteArray? = withContext(Dispatchers.Default) {
        if (activeBitmap == null || outlineMask == null) return@withContext null

        SmartBrushEngine.applyBoundedStroke(
            activeBitmap!!, outlineMask!!, activeWidth, activeHeight,
            points, color, radius, startX, startY, isEraser
        )
        
        return@withContext getEncodedBytes()
    }

    // Nén ảnh đang có trong RAM thành ByteArray để Flutter hiển thị
    private fun getEncodedBytes(): ByteArray {
        val stream = java.io.ByteArrayOutputStream()
        // Dùng PNG để giữ độ trong suốt
        activeBitmap!!.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
}
