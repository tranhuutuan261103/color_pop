import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'core/providers/theme_provider.dart';

void main() {
  // Đảm bảo cầu nối giữa Flutter framework và engine đã sẵn sàng.
  // Bắt buộc phải có nếu cần gọi Native Code hoặc các tác vụ async (như Firebase, SharedPreferences) trước runApp.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        // ChangeNotifierProvider quản lý và lắng nghe sự thay đổi từ ThemeProvider.
        // Dấu '_' nghĩa là chúng ta bỏ qua tham số BuildContext vì không cần dùng đến khi khởi tạo.
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}