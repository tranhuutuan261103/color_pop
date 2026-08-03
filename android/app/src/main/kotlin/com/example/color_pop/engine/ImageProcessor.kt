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
    // LƯU TRỮ RAM (STATE) - Biến global quản lý ảnh hiện tại
    var activeBitmap: Bitmap? = null // Bỏ private để các engine khác truy cập nếu cần
    var outlineMask: ByteArray? = null // Bỏ private để FloodFill có thể kiểm tra viền
    var activeWidth = 0
    var activeHeight = 0

    // 1. Load ảnh vào RAM (Dùng khi mở Project cũ hoặc load ảnh mới)
    suspend fun loadProjectToRAM(path: String): ByteArray? = withContext(Dispatchers.IO) {
        activeBitmap?.recycle() // Xóa ảnh cũ để tránh rò rỉ bộ nhớ
        
        // Cần đảm bảo Bitmap tạo ra là Mutable (có thể vẽ lên được)
        val loadedBitmap = BitmapLoader.load(path) ?: return@withContext null
        activeBitmap = loadedBitmap.copy(Bitmap.Config.ARGB_8888, true)
        loadedBitmap.recycle()
        
        activeWidth = activeBitmap!!.width
        activeHeight = activeBitmap!!.height

        // Tự động tạo Mask viền đen lưu lại để dùng cho Smart Brush và Flood Fill
        outlineMask = OutlineMaskBuilder.build(activeBitmap!!, 120, false)

        // Trả về ByteArray (chuẩn PNG/JPEG) cho Flutter hiển thị
        return@withContext getEncodedBytes()
    }

    // 2. Chuyển đổi đen trắng & Trả về thông tin đầy đủ cho Flutter
    suspend fun processGrayscale(inputPath: String, outputPath: String): Map<String, Any>? {
        val bitmap = BitmapLoader.load(inputPath) ?: return null
        val width = bitmap.width
        val height = bitmap.height
        
        val pixels = BitmapCache.getPixelsFromBitmap(bitmap)
        bitmap.recycle()

        GrayScaleProcessor.processInPlace(pixels)
        
        val saved = BitmapSaver.saveFromPixels(pixels, width, height, outputPath)
        BitmapCache.releaseIntArray(pixels) // Trả mảng về Pool
        
        if (!saved) return null

        return mapOf(
            "path" to outputPath,
            "width" to width,
            "height" to height
        )
    }

    // 3. Lấy thông tin kích thước ảnh (Chỉ đọc Header EXIF)
    suspend fun getImageInfo(path: String): Map<String, Int>? = withContext(Dispatchers.IO) {
        try {
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
        val bitmap = BitmapLoader.load(inputPath) ?: return null
        val mask = OutlineMaskBuilder.build(bitmap, threshold, applyBlur = true)
        bitmap.recycle()
        return mask
    }

    // =========================================================================
    // NHÓM 5 CÔNG CỤ VẼ 
    // Mọi công cụ giờ đây sẽ vẽ TRỰC TIẾP lên activeBitmap trên RAM
    // và trả về ngay file ByteArray cho Flutter hiển thị chớp nhoáng
    // =========================================================================

    // [TÍNH NĂNG 1]: BÚT CHÌ (Vẽ nét tự do)
    suspend fun applyPencil(points: DoubleArray, color: Int, radius: Float): Boolean {
        if (activeBitmap == null) return false
        
        // Rút pixel ra thao tác
        val pixels = BitmapCache.getPixelsFromBitmap(activeBitmap!!)
        
        // PencilEngine xử lý cập nhật mảng pixel
        PencilEngine.drawStroke(pixels, activeWidth, activeHeight, points, color, radius)
        
        // Gán mảng pixel mới trở lại activeBitmap
        activeBitmap!!.setPixels(pixels, 0, activeWidth, 0, 0, activeWidth, activeHeight)
        
        // Trả mảng nháp về Pool
        BitmapCache.releaseIntArray(pixels)
        return true
    }

    // [TÍNH NĂNG 2]: TẨY (Làm trong suốt)
    suspend fun applyEraser(points: DoubleArray, radius: Float): Boolean {
        if (activeBitmap == null) return false
        
        val pixels = BitmapCache.getPixelsFromBitmap(activeBitmap!!)
        
        EraserEngine.eraseStroke(pixels, activeWidth, activeHeight, points, radius)
        
        activeBitmap!!.setPixels(pixels, 0, activeWidth, 0, 0, activeWidth, activeHeight)
        BitmapCache.releaseIntArray(pixels)
        return true
    }

    // [TÍNH NĂNG 3]: CỌ THÔNG MINH (Chỉ vẽ vùng trống)
    // Đã xóa tham số isEraser bị thừa
    suspend fun applySmartBrush(
        points: DoubleArray, color: Int, radius: Float, startX: Int, startY: Int
    ): ByteArray? = withContext(Dispatchers.Default) {
        if (activeBitmap == null || outlineMask == null) return@withContext null

        SmartBrushEngine.applyBoundedStroke(
            activeBitmap!!, outlineMask!!, activeWidth, activeHeight,
            points, color, radius, startX, startY, false // Ép false vì Tẩy đã tách luồng
        )
        
        return@withContext getEncodedBytes()
    }

    // [TÍNH NĂNG 4]: THÙNG SƠN (Flood Fill / Loang màu)
    suspend fun applyFloodFill(startX: Int, startY: Int, color: Int): ByteArray? = withContext(Dispatchers.Default) {
        if (activeBitmap == null || outlineMask == null) return@withContext null

        FloodFillEngine.applyFill(
            activeBitmap!!, outlineMask!!, activeWidth, activeHeight, startX, startY, color
        )
        
        return@withContext getEncodedBytes()
    }

    // [TÍNH NĂNG 5]: BÌNH XỊT (Spray / Airbrush)
    suspend fun applySpray(
        points: DoubleArray, color: Int, radius: Float, density: Float
    ): ByteArray? = withContext(Dispatchers.Default) {
        if (activeBitmap == null) return@withContext null

        SprayEngine.applySpray(
            activeBitmap!!, points, color, radius, density
        )
        
        return@withContext getEncodedBytes()
    }

    // Nén ảnh đang có trong RAM thành ByteArray để Flutter hiển thị
    private fun getEncodedBytes(): ByteArray {
        val stream = java.io.ByteArrayOutputStream()
        // Bắt buộc dùng PNG để hỗ trợ kênh Alpha (Độ trong suốt của màu)
        activeBitmap!!.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
}