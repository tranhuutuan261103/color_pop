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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

// Lắng nghe yêu cầu từ Flutter (Dart), bóc tách dữ liệu an toàn, 
// điều phối cho ImageProcessor xử lý và gửi kết quả trả về.
object NativeBridge {
    // Tên định danh kênh giao tiếp
    private const val CHANNEL = "com.fau.color_pop/image_processor"

    fun register(flutterEngine: FlutterEngine) {
        // Đăng ký bộ lắng nghe sự kiện trên Flutter Engine
        // Lớp thực hiện việc mở kênh. Nó cần binaryMessenger (hệ thống truyền tin nhị phân của Flutter Engine) và tên kênh (CHANNEL).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            // call.method: Tên hàm mà file workspace_logic.dart (Flutter) gọi
            when (call.method) {
                
                // --- LUỒNG 1: XỬ LÝ ẢNH TRẮNG ĐEN ---
                "processGrayscale" -> {
                    // 1. Bóc tách tham số. Dùng Elvis operator (?:) để chặn lỗi Null ngay lập tức.
                    val inputPath = call.argument<String>("inputPath") ?: return@setMethodCallHandler result.error("ERR", "Missing inputPath", null)
                    val outputPath = call.argument<String>("outputPath") ?: return@setMethodCallHandler result.error("ERR", "Missing outputPath", null)
                    
                    // 2. Mở một Coroutine trên luồng chính (Main Thread) để đợi kết quả
                    // Kỹ thuật Bất đồng bộ với Coroutines
                    CoroutineScope(Dispatchers.Main).launch {
                        // Gọi ImageProcessor xử lý (Hàm này chạy ngầm trên Background Thread)
                        val infoMap = ImageProcessor.processGrayscale(inputPath, outputPath)
                        // 3. Trả kết quả về cho Flutter UI
                        if (infoMap != null) {
                            result.success(infoMap) // Trả về dạng Map {path, width, height}
                        } else {
                            result.error("ERR", "Native error: Unable to process Grayscale", null)
                        }
                    }
                }
                
                // --- LUỒNG 2: ĐỌC THÔNG SỐ ẢNH ---
                "getImageInfo" -> {
                    val path = call.argument<String>("path") ?: return@setMethodCallHandler result.error("ERR", "Missing path", null)
                    
                    CoroutineScope(Dispatchers.Main).launch {
                        val infoMap = ImageProcessor.getImageInfo(path)
                        if (infoMap != null) {
                            result.success(infoMap) // Gửi {width, height} về Flutter
                        } else {
                            result.error("ERR", "Native error: Unable to read image dimensions.", null)
                        }
                    }
                }
                
                // --- LUỒNG 3: DÒ TÌM ĐƯỜNG VIỀN ---
                "buildOutlineMask" -> {
                    val inputPath = call.argument<String>("inputPath") ?: return@setMethodCallHandler result.error("ERR", "Missing inputPath", null)
                    // Nếu Flutter không gửi threshold, mặc định dùng 120
                    val threshold = call.argument<Int>("threshold") ?: 120
                    
                    CoroutineScope(Dispatchers.Main).launch {
                        // Tính toán mảng 1D chứa các pixel viền ảnh
                        val maskBytes = ImageProcessor.buildOutlineMask(inputPath, threshold)
                        if (maskBytes != null) {
                            result.success(maskBytes) // maskBytes là ByteArray, truyền thẳng sang Uint8List của Dart rất mượt
                        } else {
                            result.error("ERR", "Native error: Unable to extract outline mask.", null)
                        }
                    }
                }

                // --- LUỒNG 4: LOAD PROJECT ---
                "loadProject" -> {
                    val path = call.argument<String>("path") ?: return@setMethodCallHandler result.error("ERR", "", null)
                    CoroutineScope(Dispatchers.Main).launch {
                        val bytes = ImageProcessor.loadProjectToRAM(path)
                        if (bytes != null) result.success(bytes) else result.error("ERR", "", null)
                    }
                }

                // --- LUỒNG 5: VẼ NÉT CỌ THÔNG MINH (SMART BRUSH) ---
                "applySmartBrush" -> {
                    val points = call.argument<DoubleArray>("points") ?: return@setMethodCallHandler result.error("ERR", "", null)
                    val color = call.argument<Long>("color")?.toInt() ?: 0
                    val radius = call.argument<Double>("radius")?.toFloat() ?: 10f
                    val startX = call.argument<Int>("startX") ?: 0
                    val startY = call.argument<Int>("startY") ?: 0
                    val isEraser = call.argument<Boolean>("isEraser") ?: false

                    CoroutineScope(Dispatchers.Main).launch {
                        // Hàm này sẽ trả về Mảng Byte của bức ảnh ĐÃ CẬP NHẬT
                        val bytes = ImageProcessor.applySmartBrush(points, color, radius, startX, startY, isEraser)
                        if (bytes != null) result.success(bytes) else result.error("ERR", "", null)
                    }
                }
                
                // --- LUỒNG NGOẠI LỆ ---
                // Bắt trường hợp Flutter gọi sai tên method chưa được khai báo
                else -> result.notImplemented()
            }
        }
    }
}