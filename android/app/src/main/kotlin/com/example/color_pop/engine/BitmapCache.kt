// ====================================================
// Nhóm 1: Quản lý I/O & Bộ nhớ (File/Bitmap/ByteArray)
// ====================================================

// 1. File BitmapCache.kt
/* Vai trò: Thay vì liên tục tạo mảng IntArray mới có kích thước 8000x8000 
(chiếm 256MB RAM) mỗi khi gọi thuật toán và để bộ dọn rác (GC) dọn dẹp gây khựng UI, 
chúng ta tạo một Pool (Hồ chứa). Dùng xong trả về hồ, lần sau lấy ra xài tiếp. */ 

package com.example.color_pop.engine

import android.graphics.Bitmap
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ConcurrentLinkedQueue

/**
 * Quản lý bộ nhớ (Memory Pool) để tái sử dụng mảng IntArray và FloatArray.
 * Giúp giảm thiểu tối đa Garbage Collection (GC) gây giật (jank) UI.
 */
object BitmapCache {
    // Lưu trữ mảng IntArray theo kích thước (size). Dùng ConcurrentLinkedQueue để thread-safe.
    private val intArrayPool = ConcurrentHashMap<Int, ConcurrentLinkedQueue<IntArray>>()

    /**
     * Lấy một mảng IntArray từ Pool. Nếu không có sẵn thì mới tạo mới.
     */
    fun obtainIntArray(size: Int): IntArray {
        val queue = intArrayPool[size]
        return queue?.poll() ?: IntArray(size)
    }

    /**
     * Trả mảng IntArray về Pool sau khi dùng xong.
     */
    fun releaseIntArray(array: IntArray) {
        val size = array.size
        val queue = intArrayPool.getOrPut(size) { ConcurrentLinkedQueue() }
        
        // Giới hạn pool tối đa 3 mảng cùng kích thước để tránh cạn kiệt RAM (Out Of Memory)
        if (queue.size < 3) {
            queue.offer(array)
        }
    }

    /**
     * Đọc toàn bộ pixel của Bitmap vào IntArray cực nhanh.
     */
    fun getPixelsFromBitmap(bitmap: Bitmap): IntArray {
        val size = bitmap.width * bitmap.height
        val pixels = obtainIntArray(size)
        bitmap.getPixels(pixels, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
        return pixels
    }
}