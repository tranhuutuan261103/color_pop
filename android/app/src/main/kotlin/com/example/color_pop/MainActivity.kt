package com.example.color_pop

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/// [MainActivity]
/// Điểm neo (Entry point) của ứng dụng trên hệ điều hành Android.
/// Chịu trách nhiệm khởi chạy Flutter Engine và gắn kết các module Native (Kotlin/C++).
class MainActivity: FlutterActivity() {
    // Hàm này được gọi tự động khi FlutterEngine vừa khởi tạo xong, 
    // trước khi giao diện Dart (Flutter UI) được vẽ lên màn hình.
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        // Luôn phải gọi super để giữ lại các cài đặt mặc định của Flutter framework
        super.configureFlutterEngine(flutterEngine)
        
        // [Gắn cầu nối MethodChannel]
        // Đăng ký các Native API (như xử lý ảnh, dò viền) vào FlutterEngine.
        // Giúp file workspace_logic.dart có thể gọi invokeMethod() xuống Android.
        NativeBridge.register(flutterEngine)
    }
}