// Thuật toán xử lý ảnh
package com.example.color_pop // ĐỔI LẠI THÀNH PACKAGE NAME CỦA BẠN

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Canvas
import android.graphics.Paint
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream

object ImageProcessor {

    // 1. Hàm chuyển ảnh sang Grayscale và lưu lại
    suspend fun processGrayscaleAndSave(inputPath: String, outputPath: String, quality: Int = 100): Boolean {
        return withContext(Dispatchers.IO) { // Chạy trên luồng nền (I/O thread)
            try {
                val bitmap = BitmapFactory.decodeFile(inputPath) ?: return@withContext false
                
                // Tạo một Bitmap đen trắng
                val bmpGrayscale = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bmpGrayscale)
                val paint = Paint()
                
                val colorMatrix = ColorMatrix()
                colorMatrix.setSaturation(0f) // Chỉnh bão hòa về 0 -> Trắng đen
                paint.colorFilter = ColorMatrixColorFilter(colorMatrix)
                canvas.drawBitmap(bitmap, 0f, 0f, paint)

                // Lưu ra file mới
                val file = File(outputPath)
                val out = FileOutputStream(file)
                bmpGrayscale.compress(Bitmap.CompressFormat.JPEG, quality, out)
                out.flush()
                out.close()
                
                bitmap.recycle() // Giải phóng RAM ngay lập tức
                bmpGrayscale.recycle()
                
                true
            } catch (e: Exception) {
                e.printStackTrace()
                false
            }
        }
    }

    // 2. Hàm trích xuất viền (Outline Mask) cực nhanh
    suspend fun buildOutlineMask(inputPath: String, threshold: Int): ByteArray? {
        return withContext(Dispatchers.Default) { // Chạy trên luồng tính toán CPU
            try {
                val bitmap = BitmapFactory.decodeFile(inputPath) ?: return@withContext null
                val width = bitmap.width
                val height = bitmap.height
                val size = width * height
                
                // Lấy toàn bộ mảng pixel 1 lần (cực nhanh so với vòng lặp Dart)
                val pixels = IntArray(size)
                bitmap.getPixels(pixels, 0, width, 0, 0, width, height)
                
                val mask = ByteArray(size)
                
                // Thuật toán dò viền cơ bản (Thresholding)
                for (i in 0 until size) {
                    val p = pixels[i]
                    val r = (p shr 16) and 0xff
                    val g = (p shr 8) and 0xff
                    val b = p and 0xff
                    
                    // Công thức tính luma (độ xám)
                    val gray = (r * 0.299 + g * 0.587 + b * 0.114).toInt()
                    
                    // Nếu pixel tối hơn threshold -> nó là nét vẽ (outline)
                    if (gray < threshold) {
                        mask[i] = 1
                    } else {
                        mask[i] = 0
                    }
                }
                
                bitmap.recycle()
                mask // Trả mảng Byte về cho Dart
            } catch (e: Exception) {
                e.printStackTrace()
                null
            }
        }
    }
}