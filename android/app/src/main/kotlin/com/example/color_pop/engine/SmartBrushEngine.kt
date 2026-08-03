package com.example.color_pop.engine

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.LinkedList

object SmartBrushEngine {

    /**
     * Thuật toán vẽ cọ thông minh chặn bởi đường viền.
     */
    suspend fun applyBoundedStroke(
        mainBitmap: Bitmap,
        outlineMask: ByteArray, // Mảng viền đen (1 là viền, 0 là khoảng trống)
        width: Int, height: Int,
        points: DoubleArray, // Tọa độ nét vẽ
        color: Int, radius: Float,
        startX: Int, startY: Int, // Điểm chạm đầu tiên để xác định vùng an toàn
        isEraser: Boolean
    ) = withContext(Dispatchers.Default) {
        
        // 1. TÌM VÙNG GIỚI HẠN (SELECTION MASK)
        val selectionMask = ByteArray(width * height)
        generateSelectionRegion(outlineMask, selectionMask, width, height, startX, startY)

        // 2. VẼ NÉT CỌ VÀO LỚP TẠM (TEMP BITMAP)
        val tempBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(tempBitmap)
        val paint = Paint().apply {
            this.color = if (isEraser) 0x00000000 else color
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

        // 3. MERGE LỚP TẠM VÀO LỚP CHÍNH CÓ CHỌN LỌC (SMART BLEND)
        val tempPixels = IntArray(width * height)
        // [FIXED] offset=0, stride=width, x=0, y=0, width=width, height=height
        tempBitmap.getPixels(tempPixels, 0, width, 0, 0, width, height)
        
        val mainPixels = IntArray(width * height)
        // [FIXED]
        mainBitmap.getPixels(mainPixels, 0, width, 0, 0, width, height)

        for (i in 0 until width * height) {
            if (selectionMask[i] == 1.toByte() && outlineMask[i] == 0.toByte()) {
                val p = tempPixels[i]
                if (p != 0) { 
                    if (isEraser) {
                        mainPixels[i] = 0x00000000
                    } else {
                        mainPixels[i] = p 
                    }
                }
            }
        }

        // 4. Cập nhật lại ảnh thật
        mainBitmap.setPixels(mainPixels, 0, width, 0, 0, width, height)
        tempBitmap.recycle()
    }

    private fun generateSelectionRegion(
        outlineMask: ByteArray, selectionMask: ByteArray, 
        w: Int, h: Int, startX: Int, startY: Int
    ) {
        val startIndex = startY * w + startX
        if (startIndex < 0 || startIndex >= outlineMask.size) return
        
        if (outlineMask[startIndex] == 1.toByte()) return

        val queue = LinkedList<Int>()
        queue.add(startIndex)
        selectionMask[startIndex] = 1

        val dx = intArrayOf(-1, 1, 0, 0)
        val dy = intArrayOf(0, 0, -1, 1)

        while (queue.isNotEmpty()) {
            val curr = queue.poll()!!
            val cx = curr % w
            val cy = curr / w

            for (i in 0..3) {
                val nx = cx + dx[i]
                val ny = cy + dy[i]
                if (nx in 0 until w && ny in 0 until h) {
                    val nIndex = ny * w + nx
                    if (outlineMask[nIndex] == 0.toByte() && selectionMask[nIndex] == 0.toByte()) {
                        selectionMask[nIndex] = 1
                        queue.add(nIndex)
                    }
                }
            }
        }
    }
}