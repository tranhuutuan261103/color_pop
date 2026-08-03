package com.example.color_pop.engine

import android.graphics.Bitmap
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Thuật toán Scanline Flood Fill siêu tốc.
 * Không dùng đệ quy (chống StackOverflow).
 * Lấp kín các viền răng cưa cực tốt.
 */
object FloodFillEngine {

    suspend fun applyFill(
        bitmap: Bitmap,
        outlineMask: ByteArray, // Vẫn giữ tham số để khớp với ImageProcessor
        width: Int,
        height: Int,
        startX: Int,
        startY: Int,
        fillColor: Int
    ) = withContext(Dispatchers.Default) {
        
        if (startX < 0 || startX >= width || startY < 0 || startY >= height) return@withContext

        val pixels = BitmapCache.getPixelsFromBitmap(bitmap)
        val targetColor = pixels[startY * width + startX]

        // Nếu màu bám vào đã giống màu cần tô -> Bỏ qua để tránh lặp vô tận
        if (targetColor == fillColor) {
            BitmapCache.releaseIntArray(pixels)
            return@withContext
        }

        // Mượn mảng từ Pool để làm Stack (Kích thước an toàn tối đa bằng số pixel)
        val stack = BitmapCache.obtainIntArray(width * height)
        var stackPointer = 0

        // Push điểm đầu tiên vào stack
        stack[stackPointer++] = startX
        stack[stackPointer++] = startY

        while (stackPointer > 0) {
            val y = stack[--stackPointer]
            var x = stack[--stackPointer]

            // Trượt sang trái đến khi đụng viền hoặc khác màu target
            while (x >= 0 && pixels[y * width + x] == targetColor) {
                x--
            }
            x++ // Lùi lại 1 bước vào trong vùng tô

            var spanAbove = false
            var spanBelow = false

            // Trượt sang phải và tô màu
            while (x < width && pixels[y * width + x] == targetColor) {
                pixels[y * width + x] = fillColor // Tô màu!

                // Kiểm tra hàng bên trên
                if (y > 0) {
                    val pAbove = pixels[(y - 1) * width + x]
                    if (!spanAbove && pAbove == targetColor) {
                        stack[stackPointer++] = x
                        stack[stackPointer++] = y - 1
                        spanAbove = true
                    } else if (spanAbove && pAbove != targetColor) {
                        spanAbove = false
                    }
                }

                // Kiểm tra hàng bên dưới
                if (y < height - 1) {
                    val pBelow = pixels[(y + 1) * width + x]
                    if (!spanBelow && pBelow == targetColor) {
                        stack[stackPointer++] = x
                        stack[stackPointer++] = y + 1
                        spanBelow = true
                    } else if (spanBelow && pBelow != targetColor) {
                        spanBelow = false
                    }
                }
                x++
            }
        }

        // Ghi lại mảng pixel đã tô thành công vào Bitmap
        bitmap.setPixels(pixels, 0, width, 0, 0, width, height)
        
        // Dùng xong trả Stack và Pixels về cho hệ thống
        BitmapCache.releaseIntArray(stack)
        BitmapCache.releaseIntArray(pixels)
    }
}