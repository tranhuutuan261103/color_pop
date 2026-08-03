// ===========================
// Nhóm 4: Tô bằng Cọ (Brush)
// ===========================

// 1. File BrushEngine.kt
/* Vai trò: Nhận mảng tọa độ từ Flutter và vẽ nét cọ lên mảng Pixel. 
Thay vì tính toán thủ công từng pixel rất phức tạp, ta tận dụng sức mạnh phần cứng GPU của 
Android thông qua android.graphics.Canvas và Paint để vẽ nét có khử răng cưa (mượt) và 
làm tròn đầu nét (Round Cap). */

package com.example.color_pop.engine

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Native Brush Engine - Xử lý vẽ nét cọ (Stroke) và Cục tẩy (Eraser) 
 * Nhận mảng pixel từ Flutter -> Wrap thành Android Bitmap -> Dùng Canvas vẽ nét -> Trả lại mảng Pixel.
 * Chạy trên Dispatchers.Default để không block UI Thread.
 */
object BrushEngine {

    suspend fun paintStroke(
        pixels: IntArray, width: Int, height: Int,
        points: DoubleArray, // Tọa độ [x1, y1, x2, y2, x3, y3...]
        color: Int, radius: Float, isEraser: Boolean
    ) = withContext(Dispatchers.Default) {
        if (points.size < 2) return@withContext // Cần ít nhất 1 cặp tọa độ (x,y)

        // 1. Wrap IntArray thành Bitmap để mượn engine render (hardware-accelerated) của Android Canvas
        val bitmap = Bitmap.createBitmap(pixels, width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // 2. Cấu hình Cọ vẽ (Paint)
        val paint = Paint().apply {
            this.color = color
            strokeWidth = radius * 2f // System dùng đường kính, app truyền vào bán kính
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND // Bo tròn đầu nét (giảm sắc cạnh)
            strokeJoin = Paint.Join.ROUND // Bo tròn khúc cua
            isAntiAlias = true // Khử răng cưa (quan trọng để nét vẽ không bị răng cưa)
            
            if (isEraser) {
                // Chế độ tẩy: Đục thủng pixel (Set Alpha = 0) thay vì vẽ đè màu lên
                xfermode = PorterDuffXfermode(PorterDuff.Mode.CLEAR)
            }
        }

        // 3. Tính toán lộ trình (Path) và Vẽ
        val path = Path()
        path.moveTo(points[0].toFloat(), points[1].toFloat())
        
        if (points.size == 2) {
            // Trường hợp người dùng chỉ chấm 1 điểm (Tap)
            paint.style = Paint.Style.FILL
            canvas.drawCircle(points[0].toFloat(), points[1].toFloat(), radius, paint)
        } else {
            // Trường hợp vẽ nét dài (Pan)
            for (i in 2 until points.size step 2) {
                val x = points[i].toFloat()
                val y = points[i + 1].toFloat()
                path.lineTo(x, y)
                
                // Mở rộng tương lai: Dùng Bezier Curve (quadTo) ở đây để làm mượt nét vẽ
                // nếu tần số quét màn hình thấp khiến nét bị gãy.
            }
            canvas.drawPath(path, paint)
        }

        // 4. Cập nhật lại kết quả từ Bitmap vào mảng IntArray gốc
        bitmap.getPixels(pixels, 0, width, 0, 0, width, height)
        bitmap.recycle() // Giải phóng RAM ngay lập tức
    }
}