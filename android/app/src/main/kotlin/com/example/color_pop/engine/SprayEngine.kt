package com.example.color_pop.engine

import android.graphics.Bitmap
import android.graphics.Color
import java.util.Random
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

object SprayEngine {
    private val random = Random()

    /**
     * @param targetBitmap Bitmap chứa lớp màu đang thao tác
     * @param points Mảng 1 chiều chứa tọa độ [x1, y1, x2, y2...]
     * @param color Mã màu ARGB (Int)
     * @param radius Bán kính bình xịt
     * @param density Mật độ hạt xịt (0.0 đến 1.0)
     */
    fun applySpray(
        targetBitmap: Bitmap, 
        points: DoubleArray?, 
        color: Int, 
        radius: Float, 
        density: Float
    ): Boolean {
        if (points == null || points.isEmpty()) return false

        val width = targetBitmap.width
        val height = targetBitmap.height

        // Số lượng hạt sinh ra trên mỗi điểm chạm phụ thuộc vào bán kính và mật độ
        val particlesPerPoint = (radius * radius * density).toInt().coerceAtLeast(5)

        for (i in points.indices step 2) {
            val cx = points[i].toFloat()
            val cy = points[i + 1].toFloat()

            for (p in 0 until particlesPerPoint) {
                // Tạo bán kính ngẫu nhiên nhưng thiên về tâm (dùng sqrt để phân bố đều trong hình tròn)
                val r = radius * sqrt(random.nextFloat())
                // Tạo góc ngẫu nhiên (0 đến 360 độ -> radians)
                val theta = random.nextFloat() * 2 * Math.PI

                // Tính tọa độ điểm hạt xịt
                val px = (cx + r * cos(theta)).toInt()
                val py = (cy + r * sin(theta)).toInt()

                // Kiểm tra giới hạn ảnh
                if (px in 0 until width && py in 0 until height) {
                    // CẬP NHẬT ALPHA BLENDING:
                    // Ở đây để đơn giản ta dùng setPixel. Nếu muốn opacity chuẩn, 
                    // nên dùng Canvas(targetBitmap) vẽ các điểm hoặc tự pha trộn (blend) màu hiện tại với màu mới.
                    targetBitmap.setPixel(px, py, color)
                }
            }
        }
        return true
    }
}