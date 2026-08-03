package com.example.color_pop.engine

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

object PencilEngine {
    suspend fun drawStroke(
        pixels: IntArray,
        width: Int,
        height: Int,
        points: DoubleArray,
        color: Int,
        radius: Float
    ) = withContext(Dispatchers.Default) {
        if (points.size < 2) return@withContext

        // [FIX LỖI VĂNG APP]: Tạo bitmap rỗng (Mutable), sau đó nạp pixel vào.
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        bitmap.setPixels(pixels, 0, width, 0, 0, width, height)

        val canvas = Canvas(bitmap)

        val paint = Paint().apply {
            this.color = color
            strokeWidth = radius * 2f
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
            isAntiAlias = true
        }

        val path = Path()
        path.moveTo(points[0].toFloat(), points[1].toFloat())

        if (points.size == 2) {
            paint.style = Paint.Style.FILL
            canvas.drawCircle(points[0].toFloat(), points[1].toFloat(), radius, paint)
        } else {
            for (i in 2 until points.size step 2) {
                path.lineTo(points[i].toFloat(), points[i + 1].toFloat())
            }
            canvas.drawPath(path, paint)
        }

        bitmap.getPixels(pixels, 0, width, 0, 0, width, height)
        bitmap.recycle()
    }
}