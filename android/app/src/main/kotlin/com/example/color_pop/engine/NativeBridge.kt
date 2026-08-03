// ==================================================================
// Nhóm 3: Quản lý điều phối I/O giữa Flutter và Native (Kotlin/Java)
// ==================================================================

// 1. File NativeBridge.kt (Cầu nối MethodChannel)
/* Vai trò: Nhận lệnh từ Flutter dưới dạng String/Map, 
gọi ImageProcessor chạy đa luồng, và trả kết quả về Flutter. 
Tách khỏi MainActivity để code sạch sẽ. */

package com.example.color_pop

import com.example.color_pop.engine.ImageProcessor
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.* 

// Lắng nghe yêu cầu từ Flutter (Dart), bóc tách dữ liệu an toàn, 
// điều phối cho ImageProcessor xử lý và gửi kết quả trả về.
object NativeBridge {
    // Tên định danh kênh giao tiếp phải khớp chính xác với biến platform bên workspace_logic.dart
    private const val CHANNEL = "com.fau.color_pop/image_processor"

    // [KIẾN TRÚC ĐA LUỒNG AN TOÀN]
    // Tạo một CoroutineScope chung gắn với vòng đời của ứng dụng.
    // Dispatchers.Main đảm bảo kết quả cuối cùng luôn được trả về UI Thread cho Flutter.
    // SupervisorJob() giúp nếu 1 tác vụ lỗi thì không làm sập toàn bộ các tác vụ khác.
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    fun register(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                
                // --- LUỒNG 1: XỬ LÝ ẢNH TRẮNG ĐEN ---
                "processGrayscale" -> {
                    val inputPath = call.argument<String>("inputPath") ?: return@setMethodCallHandler result.error("ERR", "Missing inputPath", null)
                    val outputPath = call.argument<String>("outputPath") ?: return@setMethodCallHandler result.error("ERR", "Missing outputPath", null)
                    
                    scope.launch {
                        val infoMap = withContext(Dispatchers.Default) {
                            ImageProcessor.processGrayscale(inputPath, outputPath)
                        }
                        if (infoMap != null) {
                            result.success(infoMap)
                        } else {
                            result.error("ERR", "Native error: Unable to process Grayscale", null)
                        }
                    }
                }
                
                // --- LUỒNG 2: ĐỌC THÔNG SỐ ẢNH ---
                "getImageInfo" -> {
                    val path = call.argument<String>("path") ?: return@setMethodCallHandler result.error("ERR", "Missing path", null)
                    
                    scope.launch {
                        val infoMap = withContext(Dispatchers.Default) {
                            ImageProcessor.getImageInfo(path)
                        }
                        if (infoMap != null) {
                            result.success(infoMap)
                        } else {
                            result.error("ERR", "Native error: Unable to read image dimensions.", null)
                        }
                    }
                }
                
                // --- LUỒNG 3: DÒ TÌM ĐƯỜNG VIỀN ---
                "buildOutlineMask" -> {
                    val inputPath = call.argument<String>("inputPath") ?: return@setMethodCallHandler result.error("ERR", "Missing inputPath", null)
                    val threshold = call.argument<Int>("threshold") ?: 120
                    
                    scope.launch {
                        val maskBytes = withContext(Dispatchers.Default) {
                            ImageProcessor.buildOutlineMask(inputPath, threshold)
                        }
                        if (maskBytes != null) {
                            result.success(maskBytes) 
                        } else {
                            result.error("ERR", "Native error: Unable to extract outline mask.", null)
                        }
                    }
                }

                // --- LUỒNG 4: LOAD PROJECT ---
                "loadProject" -> {
                    val path = call.argument<String>("path") ?: return@setMethodCallHandler result.error("ERR", "", null)
                    scope.launch {
                        val bytes = withContext(Dispatchers.Default) {
                            ImageProcessor.loadProjectToRAM(path)
                        }
                        if (bytes != null) result.success(bytes) else result.error("ERR", "", null)
                    }
                }

                // ===================================================================================
                // NHÓM 5 TÍNH NĂNG VẼ (Đã được tách bạch rõ ràng)
                // ===================================================================================

                // [TÍNH NĂNG 1]: BÚT CHÌ (PENCIL)
                "applyPencilStroke" -> {
                    val points = call.argument<DoubleArray>("points") ?: return@setMethodCallHandler result.error("ERR", "Missing points", null)
                    val color = call.argument<Long>("color")?.toInt() ?: 0
                    val radius = call.argument<Double>("radius")?.toFloat() ?: 10f

                    scope.launch {
                        val success = withContext(Dispatchers.Default) {
                            // Gọi đích danh hàm xử lý chì trong ImageProcessor
                            ImageProcessor.applyPencil(points, color, radius)
                        }
                        result.success(success)
                    }
                }

                // [TÍNH NĂNG 2]: TẨY (ERASER)
                // Hoàn toàn không bóc tách tham số "color" vì tẩy làm trong suốt pixel
                "applyEraserStroke" -> {
                    val points = call.argument<DoubleArray>("points") ?: return@setMethodCallHandler result.error("ERR", "Missing points", null)
                    val radius = call.argument<Double>("radius")?.toFloat() ?: 10f

                    scope.launch {
                        val success = withContext(Dispatchers.Default) {
                            // Gọi đích danh hàm xử lý tẩy trong ImageProcessor
                            ImageProcessor.applyEraser(points, radius)
                        }
                        result.success(success)
                    }
                }

                // [TÍNH NĂNG 3]: CỌ THÔNG MINH (SMART BRUSH)
                "applySmartBrush" -> {
                    val points = call.argument<DoubleArray>("points") ?: return@setMethodCallHandler result.error("ERR", "Missing points", null)
                    val color = call.argument<Long>("color")?.toInt() ?: 0
                    val radius = call.argument<Double>("radius")?.toFloat() ?: 10f
                    val startX = call.argument<Int>("startX") ?: 0
                    val startY = call.argument<Int>("startY") ?: 0

                    scope.launch {
                        val bytes = withContext(Dispatchers.Default) {
                            ImageProcessor.applySmartBrush(points, color, radius, startX, startY)
                        }
                        if (bytes != null) result.success(bytes) else result.error("ERR", "Smart brush failed", null)
                    }
                }

                // [TÍNH NĂNG 4]: THÙNG SƠN (FLOOD FILL)
                "applyFloodFill" -> {
                    val startX = call.argument<Int>("startX") ?: 0
                    val startY = call.argument<Int>("startY") ?: 0
                    val color = call.argument<Long>("color")?.toInt() ?: 0

                    scope.launch {
                        val bytes = withContext(Dispatchers.Default) {
                            ImageProcessor.applyFloodFill(startX, startY, color)
                        }
                        if (bytes != null) result.success(bytes) else result.error("ERR", "Flood fill failed", null)
                    }
                }

                // [TÍNH NĂNG 5]: BÌNH XỊT (SPRAY)
                "applySpray" -> {
                    val points = call.argument<DoubleArray>("points") ?: return@setMethodCallHandler result.error("ERR", "Missing points", null)
                    val color = call.argument<Long>("color")?.toInt() ?: 0
                    val radius = call.argument<Double>("radius")?.toFloat() ?: 10f
                    val density = call.argument<Double>("density")?.toFloat() ?: 0.5f 

                    scope.launch {
                        val bytes = withContext(Dispatchers.Default) {
                            ImageProcessor.applySpray(points, color, radius, density)
                        }
                        if (bytes != null) result.success(bytes) else result.error("ERR", "Spray failed", null)
                    }
                }
                
                // --- LUỒNG NGOẠI LỆ ---
                else -> result.notImplemented()
            }
        }
    }
}