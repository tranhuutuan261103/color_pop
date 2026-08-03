package com.example.color_pop.engine

import android.graphics.Bitmap

/**
 * Thuật toán Cọ Thông Minh (Smart Brush) - Bản Nâng Cấp Vùng Khóa
 * Tự động nội suy nét đứt gãy bằng Bresenham & Giới hạn tuyệt đối nét vẽ 
 * trong vùng kín ban đầu.
 */
object SmartBrushEngine {

    private var regionMask: ByteArray? = null
    private var lastAnchorX: Int = -1
    private var lastAnchorY: Int = -1
    private var lastWidth: Int = -1
    private var lastHeight: Int = -1

    fun applyBoundedStroke(
        bitmap: Bitmap,
        outlineMask: ByteArray,
        width: Int,
        height: Int,
        points: DoubleArray,
        color: Int,
        radius: Float,
        startX: Int,
        startY: Int,
        isEraser: Boolean
    ) {
        if (points.size < 2) return

        // 1. Dựng Hàng rào vô hình (Region Mask) bằng Flood Fill.
        // Chỉ tính toán 1 lần duy nhất lúc người dùng vừa chạm ngón tay (tọa độ neo thay đổi).
        if (regionMask == null || lastWidth != width || lastHeight != height || startX != lastAnchorX || startY != lastAnchorY) {
            buildRegionMask(outlineMask, width, height, startX, startY)
            lastAnchorX = startX
            lastAnchorY = startY
            lastWidth = width
            lastHeight = height
        }

        val pixels = BitmapCache.getPixelsFromBitmap(bitmap)
        
        // 2. Nội suy khoảng trống (Bresenham)
        for (i in 0 until points.size - 2 step 2) {
            val x0 = points[i].toInt()
            val y0 = points[i + 1].toInt()
            val x1 = points[i + 2].toInt()
            val y1 = points[i + 3].toInt()

            val dx = Math.abs(x1 - x0)
            val dy = -Math.abs(y1 - y0)
            var sx = if (x0 < x1) 1 else -1
            var sy = if (y0 < y1) 1 else -1
            var err = dx + dy
            var cx = x0
            var cy = y0

            while (true) {
                drawCircleBounded(pixels, regionMask!!, width, height, cx, cy, radius, color)
                if (cx == x1 && cy == y1) break
                val e2 = 2 * err
                if (e2 >= dy) { err += dy; cx += sx }
                if (e2 <= dx) { err += dx; cy += sy }
            }
        }

        if (points.size == 2) {
            drawCircleBounded(pixels, regionMask!!, width, height, points[0].toInt(), points[1].toInt(), radius, color)
        }

        bitmap.setPixels(pixels, 0, width, 0, 0, width, height)
        BitmapCache.releaseIntArray(pixels)
    }

    private fun buildRegionMask(outlineMask: ByteArray, width: Int, height: Int, startX: Int, startY: Int) {
        val size = width * height
        if (regionMask == null || regionMask!!.size != size) {
            regionMask = ByteArray(size) // Cấp phát 1 lần để tái sử dụng
        } else {
            regionMask!!.fill(0) // Xóa dữ liệu cũ
        }

        val safeX = startX.coerceIn(0, width - 1)
        val safeY = startY.coerceIn(0, height - 1)
        val startIndex = safeY * width + safeX

        // Nếu điểm neo (Anchor) bị chấm trúng lên viền đen -> Bỏ qua
        if (outlineMask[startIndex] > 0.toByte()) return

        // Dùng mảng Queue như Flood Fill để loang lấy vùng an toàn
        val queue = BitmapCache.obtainIntArray(size)
        var head = 0
        var tail = 0

        regionMask!![startIndex] = 1
        queue[tail++] = startIndex

        while (head < tail) {
            val curr = queue[head++]
            val cx = curr % width
            val cy = curr / width

            if (cx > 0) {
                val left = curr - 1
                if (outlineMask[left] == 0.toByte() && regionMask!![left] == 0.toByte()) {
                    regionMask!![left] = 1; queue[tail++] = left
                }
            }
            if (cx < width - 1) {
                val right = curr + 1
                if (outlineMask[right] == 0.toByte() && regionMask!![right] == 0.toByte()) {
                    regionMask!![right] = 1; queue[tail++] = right
                }
            }
            if (cy > 0) {
                val top = curr - width
                if (outlineMask[top] == 0.toByte() && regionMask!![top] == 0.toByte()) {
                    regionMask!![top] = 1; queue[tail++] = top
                }
            }
            if (cy < height - 1) {
                val bottom = curr + width
                if (outlineMask[bottom] == 0.toByte() && regionMask!![bottom] == 0.toByte()) {
                    regionMask!![bottom] = 1; queue[tail++] = bottom
                }
            }
        }
        BitmapCache.releaseIntArray(queue)
    }

    private fun drawCircleBounded(
        pixels: IntArray, regionMask: ByteArray, w: Int, h: Int, 
        cx: Int, cy: Int, r: Float, color: Int
    ) {
        val rInt = r.toInt()
        for (y in (cy - rInt)..(cy + rInt)) {
            for (x in (cx - rInt)..(cx + rInt)) {
                if (x in 0 until w && y in 0 until h) {
                    val dx = x - cx
                    val dy = y - cy
                    if (dx * dx + dy * dy <= r * r) {
                        val idx = y * w + x
                        // KIỂM TRA QUAN TRỌNG: Chỉ vẽ nếu Pixel thuộc Vùng An Toàn ban đầu
                        if (regionMask[idx] == 1.toByte()) {
                            pixels[idx] = color
                        }
                    }
                }
            }
        }
    }
}