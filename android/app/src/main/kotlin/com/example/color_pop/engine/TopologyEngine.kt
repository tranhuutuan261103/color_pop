package com.example.color_pop.engine

import android.graphics.Color
import kotlin.math.abs
import kotlin.math.sqrt

// import org.opencv.android.Utils
// import org.opencv.core.Mat
// import org.opencv.imgproc.Imgproc
// import org.opencv.core.Size

// Dữ liệu dùng chung cho Vectorization
data class Point2D(val x: Float, val y: Float)

data class ColoredPath(
    val color: Int,
    val outerBoundary: List<Point2D>,
    val holes: List<List<Point2D>> = emptyList(),
    val isStroke: Boolean = true
)

object TopologyEngine {

    /* 
     * [THÔNG BÁO] 
     * Tất cả các thuật toán tách viền thủ công (Sobel, Canny) đã bị vô hiệu hoá (comment).
     * Hiện tại dự án đã thay thế bằng mô hình AI (hed_mobile_quant.tflite) 
     * để tách viền ảnh trực tiếp từ bên Flutter (EdgeDetectionService.dart).
     * 
     * Sau khi AI xử lý xong, ảnh viền trắng đen sẽ được đẩy xuống NativeBridge 
     * và xử lý phân vùng thông qua VectorizationEngine.
     */

    /*
    fun extractRegions(pixels: IntArray, width: Int, height: Int): List<ColoredPath> {
        ... (Đã thay thế bằng VectorizationEngine)
    }
    
    private fun detectEdgesSobel(pixels: IntArray, width: Int, height: Int): BooleanArray {
        ... (Đã thay thế bằng AI Model)
    }

    private fun getLuminance(color: Int): Int {
        ...
    }
    */
}