package com.example.color_pop.engine

import android.graphics.Bitmap
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream

object BitmapSaver {
    /**
     * Lưu ảnh Bitmap xuống File Storage. Chạy ngầm trên luồng I/O.
     */
    suspend fun save(bitmap: Bitmap, outputPath: String, quality: Int = 100): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                val file = File(outputPath)
                val out = FileOutputStream(file)
                // Compress dạng JPEG cho app vẽ (nhanh, nhẹ)
                bitmap.compress(Bitmap.CompressFormat.JPEG, quality, out)
                out.flush()
                out.close()
                true
            } catch (e: Exception) {
                e.printStackTrace()
                false
            }
        }
    }

    /**
     * Tiện ích: Lưu mảng pixel thô thành file ảnh ngay lập tức.
     */
    suspend fun saveFromPixels(
        pixels: IntArray, 
        width: Int, 
        height: Int, 
        outputPath: String
    ): Boolean {
        val bitmap = Bitmap.createBitmap(pixels, width, height, Bitmap.Config.ARGB_8888)
        val result = save(bitmap, outputPath)
        bitmap.recycle() // Recycle ngay để nhả RAM
        return result
    }
}