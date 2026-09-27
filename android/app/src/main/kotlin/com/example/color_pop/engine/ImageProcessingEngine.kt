package com.example.color_pop.engine

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.File
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

object ImageProcessingEngine {

    suspend fun processAndCreateCpop(inputPath: String, outputPath: String): Boolean {
        return withContext(Dispatchers.Default) {
            try {
                android.util.Log.d("ColorPop", "[NATIVE] Request received")
                android.util.Log.d("ColorPop", "[NATIVE] Input path = $inputPath")
                val file = File(inputPath)
                if (!file.exists()) return@withContext false

                val options = BitmapFactory.Options()
                options.inPreferredConfig = Bitmap.Config.ARGB_8888
                var bitmap = BitmapFactory.decodeFile(inputPath, options) ?: return@withContext false

                // Vectorization cost grows quickly with pixel count. Keep enough
                // detail for coloring while avoiding multi-million-pixel scans.
                val maxSize = 1024
                if (bitmap.width > maxSize || bitmap.height > maxSize) {
                    val scale = maxSize.toFloat() / Math.max(bitmap.width, bitmap.height)
                    val newWidth = (bitmap.width * scale).toInt()
                    val newHeight = (bitmap.height * scale).toInt()
                    val scaled = Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
                    bitmap.recycle()
                    bitmap = scaled
                }

                val width = bitmap.width
                val height = bitmap.height
                android.util.Log.d("ColorPop", "[NATIVE] Image decoded")
                android.util.Log.d("ColorPop", "[NATIVE] Width = $width")
                android.util.Log.d("ColorPop", "[NATIVE] Height = $height")
                android.util.Log.d("ColorPop", "[NATIVE] Pixel count = ${width * height}")
                
                android.util.Log.d("ColorPop", "[NATIVE] Preprocessing completed")
                val pixels = IntArray(width * height)
                bitmap.getPixels(pixels, 0, width, 0, 0, width, height)
                
                android.util.Log.d("ColorPop", "[NATIVE] Region extraction started (Ink + Background)")
                // For coloring pages, we don't apply Sobel. We use the grayscale thresholded pixels directly.
                val regions = VectorizationEngine.vectorize(pixels, width, height)
                val inkRegions = regions.count { it.isStroke }
                val backgroundRegions = regions.count { !it.isStroke }
                
                android.util.Log.d("ColorPop", "[NATIVE] Region extraction completed")
                android.util.Log.d("ColorPop", "[NATIVE] Ink paths = $inkRegions")
                android.util.Log.d("ColorPop", "[NATIVE] Region count = $backgroundRegions")
                
                android.util.Log.d("ColorPop", "[NATIVE] Topology started")
                // Currently topology is merged into vectorization. If explicit topology graph is added, log it here.
                android.util.Log.d("ColorPop", "[NATIVE] Topology completed")
                
                android.util.Log.d("ColorPop", "[NATIVE] Serialization started")
                val success = ColorPopWriter.writeToFile(regions, width.toDouble(), height.toDouble(), outputPath)
                
                if (success) {
                    val outFile = File(outputPath)
                    android.util.Log.d("ColorPop", "[NATIVE] Serialization completed")
                    android.util.Log.d("ColorPop", "[NATIVE] Serialized size = ${outFile.length()} bytes")
                    android.util.Log.d("ColorPop", "[NATIVE] ColorPopDocument created")
                }
                
                bitmap.recycle()
                return@withContext success
            } catch (e: Exception) {
                e.printStackTrace()
                return@withContext false
            }
        }
    }
}
