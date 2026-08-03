package com.example.color_pop.engine

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

object BitmapLoader {
    /**
     * Load ảnh an toàn từ file path.
     * Chạy trên luồng I/O.
     */
    suspend fun load(path: String): Bitmap? = withContext(Dispatchers.IO) {
        try {
            val options = BitmapFactory.Options()
            
            // 1. Kiểm tra kích thước trước
            options.inJustDecodeBounds = true
            BitmapFactory.decodeFile(path, options)
            
            // 2. Nếu ảnh lớn hơn 4096, tự động tính tỷ lệ nén
            options.inSampleSize = ImageScaler.calculateInSampleSize(
                options, 
                4096, 
                4096
            )
            
            // 3. Tiến hành load ảnh thực sự
            options.inJustDecodeBounds = false
            options.inMutable = true // BẮT BUỘC: Để có thể chỉnh sửa pixel được
            options.inPreferredConfig = Bitmap.Config.ARGB_8888 
            
            BitmapFactory.decodeFile(path, options)
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}