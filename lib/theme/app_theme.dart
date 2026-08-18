import 'package:flutter/material.dart';

abstract final class AppColors {
  static const black = Color(0xFF070706);
  static const charcoal = Color(0xFF171713);
  static const gold = Color(0xFFD4AF5A);
  static const paleGold = Color(0xFFFFE7A3);
  static const deepGold = Color(0xFF73521C);

  static const metallicGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepGold, paleGold, gold, Color(0xFF4E3510)],
    stops: [0, 0.34, 0.68, 1],
  );

  static const blackShimmer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF050504), Color(0xFF211F18), Color(0xFF090908)],
    stops: [0, 0.48, 1],
  );
}

abstract final class AppTheme {
  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.gold,
      brightness: Brightness.dark,
      surface: AppColors.charcoal,
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.black,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.paleGold,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.gold.withValues(alpha: 0.28),
        thickness: 1,
      ),
    );
  }
}
