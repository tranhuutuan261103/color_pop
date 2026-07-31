import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/theme/app_theme.dart';
import '../core/providers/theme_provider.dart';
import 'app_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        ThemeData getTheme() {
          switch (themeProvider.appThemeMode) {
            case AppThemeMode.light2:
              return AppTheme.lightTheme2;
            case AppThemeMode.light1:
            case AppThemeMode.system:
            case AppThemeMode.dark:
              return AppTheme.lightTheme1;
          }
        }

        return MaterialApp(
          title: 'Color Pop',
          debugShowCheckedModeBanner: false,

          theme: getTheme(),
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          themeAnimationDuration: const Duration(milliseconds: 350),
          themeAnimationCurve: Curves.easeInOutCubic,

          initialRoute: AppRouter.homeRoute,
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
}