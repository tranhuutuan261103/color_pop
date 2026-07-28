import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme1 {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primaryBlue,
      primaryColorDark: AppColors.primaryDarkBlue,
      scaffoldBackgroundColor: AppColors.backgroundBlue,
      cardColor: AppColors.cardBlue,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.secondaryBlue,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.primaryText),
        bodyMedium: TextStyle(color: AppColors.primaryText),
        titleLarge: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundBlue,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryText),
        titleTextStyle: TextStyle(color: AppColors.primaryText, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryDarkBlue,
        unselectedItemColor: AppColors.secondaryText,
      ),
    );
  }

  static ThemeData get lightTheme2 {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primaryPink,
      primaryColorDark: AppColors.primaryDarkPink,
      scaffoldBackgroundColor: AppColors.backgroundPink,
      cardColor: AppColors.cardPink,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryPink,
        secondary: AppColors.secondaryPink,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.primaryText),
        bodyMedium: TextStyle(color: AppColors.primaryText),
        titleLarge: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundPink,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryText),
        titleTextStyle: TextStyle(color: AppColors.primaryText, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryDarkPink,
        unselectedItemColor: AppColors.secondaryText,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryPink, 
      primaryColorDark: AppColors.primaryDarkPink,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      cardColor: AppColors.cardDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryPink,
        secondary: AppColors.secondaryPink,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.primaryTextDark),
        bodyMedium: TextStyle(color: AppColors.primaryTextDark),
        titleLarge: TextStyle(color: AppColors.primaryTextDark, fontWeight: FontWeight.bold),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryTextDark),
        titleTextStyle: TextStyle(color: AppColors.primaryTextDark, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardDark,
        selectedItemColor: AppColors.primaryPink,
        unselectedItemColor: AppColors.secondaryTextDark,
      ),
    );
  }
}