import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/home/cubit/home_cubit.dart';
import '../features/main/view/main_screen.dart';
import '../features/creator/view/workspace_screen.dart';
import '../features/history/view/history_screen.dart';

class AppRouter {
  static const String homeRoute = '/';
  static const String workspaceRoute = '/workspace';
  static const String historyRoute = '/history';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case homeRoute:
        return MaterialPageRoute(
          // Tải HomeCubit vào UI và tải dữ liệu ngay lập tức
          builder: (_) => BlocProvider(
            create: (_) => HomeCubit()..loadHomeData(),
            child: const MainScreen(),
          ),
        );
      case workspaceRoute:
        // Hứng dữ liệu (đường dẫn ảnh) được truyền sang
        final imagePath = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => WorkspaceScreen(imagePath: imagePath),
        );
      case historyRoute:
        return MaterialPageRoute(
          builder: (_) => const HistoryScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}