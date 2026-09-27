package com.example.color_pop.engine

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.* 

object NativeBridge {
    private const val CHANNEL = "com.fau.color_pop/image_processor"
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    fun register(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Lệnh tạo file .cpop từ đường dẫn ảnh
                "createColorPopDocument" -> {
                    val inputPath = call.argument<String>("inputPath") ?: return@setMethodCallHandler result.error("ERR", "Missing inputPath", null)
                    val outputPath = call.argument<String>("outputPath") ?: return@setMethodCallHandler result.error("ERR", "Missing outputPath", null)
                    
                    scope.launch {
                        val success = ImageProcessingEngine.processAndCreateCpop(inputPath, outputPath)
                        if (success) {
                            result.success(outputPath)
                        } else {
                            result.error("ERR", "Failed to process image and create CPOP document", null)
                        }
                    }
                }
                
                else -> result.notImplemented()
            }
        }
    }
}