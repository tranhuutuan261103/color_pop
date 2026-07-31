package com.example.color_pop 

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity: FlutterActivity() {
    // Tên kênh giao tiếp (phải khớp với tên khai báo bên Dart)
    private val CHANNEL = "com.fau.color_pop/image_processor"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Nhận lệnh xử lý Grayscale
                "processGrayscale" -> {
                    val inputPath = call.argument<String>("inputPath")
                    val outputPath = call.argument<String>("outputPath")
                    
                    if (inputPath != null && outputPath != null) {
                        CoroutineScope(Dispatchers.Main).launch {
                            val success = ImageProcessor.processGrayscaleAndSave(inputPath, outputPath)
                            if (success) result.success(true) else result.error("ERROR", "Failed to process image", null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Missing paths", null)
                    }
                }
                
                // Nhận lệnh trích xuất mặt nạ viền
                "buildOutlineMask" -> {
                    val inputPath = call.argument<String>("inputPath")
                    val threshold = call.argument<Int>("threshold") ?: 140
                    
                    if (inputPath != null) {
                        CoroutineScope(Dispatchers.Main).launch {
                            val mask = ImageProcessor.buildOutlineMask(inputPath, threshold)
                            if (mask != null) result.success(mask) else result.error("ERROR", "Failed to build mask", null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Missing path", null)
                    }
                }
                
                else -> result.notImplemented()
            }
        }
    }
}