package com.example.color_pop.engine

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log

object ImageScaler {
    private const val MAX_SAFE_DIMENSION = 4096 // Giới hạn an toàn trên hầu hết GPU mobile

    /**
     * Tính toán inSampleSize (Tỷ lệ thu nhỏ) khi load ảnh. 
     * Ví dụ inSampleSize = 2 sẽ load ảnh giảm 1 nửa width/height (giảm 4 lần dung lượng RAM).
     */
    fun calculateInSampleSize(options: BitmapFactory.Options, reqWidth: Int, reqHeight: Int): Int {
        val (height: Int, width: Int) = options.outHeight to options.outWidth
        var inSampleSize = 1

        if (height > reqHeight || width > reqWidth) {
            val halfHeight: Int = height / 2
            val halfWidth: Int = width / 2
            while (halfHeight / inSampleSize >= reqHeight && halfWidth / inSampleSize >= reqWidth) {
                inSampleSize *= 2
            }
        }
        return inSampleSize
    }

    /**
     * Lấy kích thước ảnh thực tế mà không cần tải ảnh vào RAM.
     */
    fun getImageBounds(path: String): Pair<Int, Int> {
        val options = BitmapFactory.Options().apply {
            inJustDecodeBounds = true
        }
        BitmapFactory.decodeFile(path, options)
        return Pair(options.outWidth, options.outHeight)
    }
}