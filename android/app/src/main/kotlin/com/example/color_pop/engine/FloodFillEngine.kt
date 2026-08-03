package com.example.color_pop.engine

/**
 * Thuật toán Scanline Flood Fill siêu tốc.
 * Không dùng đệ quy (chống StackOverflow).
 * Không tạo Object trong vòng lặp (Zero-allocation).
 */
object FloodFillEngine {

    fun fill(pixels: IntArray, width: Int, height: Int, startX: Int, startY: Int, fillColor: Int) {
        val startIndex = startY * width + startX
        val targetColor = pixels[startIndex]

        // Nếu màu bám vào đã giống màu cần tô -> Bỏ qua để tránh lặp vô tận
        if (targetColor == fillColor) return

        // Mượn mảng từ Pool để làm Stack (Kích thước an toàn tối đa bằng số pixel)
        // Stack này sẽ lưu tọa độ X, Y xen kẽ nhau: stack[0]=x, stack[1]=y...
        val stack = BitmapCache.obtainIntArray(width * height)
        var stackPointer = 0

        // Push điểm đầu tiên vào stack
        stack[stackPointer++] = startX
        stack[stackPointer++] = startY

        while (stackPointer > 0) {
            // Pop tọa độ Y, X ra
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

        // Dùng xong trả Stack về cho hệ thống
        BitmapCache.releaseIntArray(stack)
    }
}