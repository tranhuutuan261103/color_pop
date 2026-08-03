import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  light1,
  light2,
  dark,
  system
}

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'app_theme_mode'; // Lưu và đọc trạng thái theme từ bộ nhớ thiết bị
  AppThemeMode _appThemeMode = AppThemeMode.system; // Trạng thái theme hiện tại

  ThemeProvider() {
    _loadTheme();
  }

  AppThemeMode get appThemeMode => _appThemeMode;

  // Getter phiên dịch từ custom theme (AppThemeMode) sang chuẩn của Flutter (ThemeMode).
  ThemeMode get themeMode {
    switch (_appThemeMode) {
      case AppThemeMode.light1:
      case AppThemeMode.light2:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final String? themeStr = prefs.getString(_themeKey);
    final String? oldThemeStr = prefs.getString('theme_mode');

    if (themeStr != null) {
      _appThemeMode = AppThemeMode.values.firstWhere(
        (e) => e.toString() == themeStr,
        orElse: () => AppThemeMode.system,
      );
      notifyListeners(); // Báo cho UI cập nhật giao diện
    } else if (oldThemeStr != null) {
      if (oldThemeStr == 'light') {
        _appThemeMode = AppThemeMode.light2;
      } else if (oldThemeStr == 'dark') {
        _appThemeMode = AppThemeMode.dark;
      } else {
        _appThemeMode = AppThemeMode.system;
      }
      notifyListeners();
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_appThemeMode == mode) return;

    // Cập nhật state và báo UI vẽ lại ngay lập tức.
    _appThemeMode = mode;
    notifyListeners();

    // Lưu thiết lập mới xuống bộ nhớ thiết bị không cần dùng 'await' để tránh chặn luồng
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_themeKey, mode.toString());
    });
  }
}