import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const Color primary        = Color(0xFF8B0000);
  static const Color primaryDark    = Color(0xFF5C0000);
  static const Color primaryLight   = Color(0xFFB71C1C);
  static const Color accent         = Color(0xFFFF1744);
  static const Color accentDark     = Color(0xFFCC0022);
  static const Color accentLight    = Color(0xFFFF5177);
  static const Color accentNeon     = Color(0xFFFF2244);
  static const Color bgDark         = Color(0xFF0A0A0A);
  static const Color bgMedium       = Color(0xFF111114);
  static const Color bgLight        = Color(0xFF1A1A1F);
  static const Color bgCard         = Color(0xFF161619);
  static const Color bgElevated     = Color(0xFF1E1E24);
  static const Color glassBase      = Color(0x14FFFFFF);
  static const Color glassBg        = Color(0x0DFFFFFF);
  static const Color glassBorder    = Color(0x1AFFFFFF);
  static const Color glassHigh      = Color(0x26FFFFFF);
  static const Color storyUnseen          = Color(0xFF8B0000);
  static const Color storySeen            = Color(0xFF3A3A3A);
  static const Color storyGradientStart   = Color(0xFFFF1744);
  static const Color storyGradientEnd     = Color(0xFF8B0000);
  static const Color textPrimary    = Color(0xFFFFFFFF);
  static const Color textSecondary  = Color(0xFFBBBBBB);
  static const Color textMuted      = Color(0xFF666680);
  static const Color bubbleSelf     = Color(0x308B0000);
  static const Color bubbleSelfBorder = Color(0x50FF1744);
  static const Color bubbleOther    = Color(0x14FFFFFF);
  static const Color bubbleOtherBorder = Color(0x1FFFFFFF);
  static const Color online         = Color(0xFF00C853);
  static const Color offline        = Color(0xFF616161);
  static const Color read           = Color(0xFF40C4FF);
  static const Color divider        = Color(0x1AFFFFFF);
  static const Color devGold        = Color(0xFFFFD700);
  AppColors._();
}

class AppGradients {
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0D0005), Color(0xFF0A0A0A), Color(0xFF0D000A)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF1744), Color(0xFFD50000)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B0000), Color(0xFF5C0000)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1A1F), Color(0xFF111114)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient drawerGradient = LinearGradient(
    colors: [Color(0xFF1A0010), Color(0xFF0D000A), Color(0xFF0A0A0A)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
  static const RadialGradient splashGlow = RadialGradient(
    center: Alignment(0, -0.2), radius: 1.2,
    colors: [Color(0xFF3D0010), Color(0xFF0D0005), Color(0xFF000000)],
  );
  AppGradients._();
}

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.bgCard,
      error: AppColors.accent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgMedium,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    tabBarTheme: const TabBarTheme(
      indicatorColor: AppColors.accent,
      labelColor: Colors.white,
      unselectedLabelColor: AppColors.textMuted,
      dividerColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgLight,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
      ),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: AppColors.bgCard,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: AppColors.glassBorder),
      ),
    ),
    dialogTheme: const DialogTheme(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: AppColors.glassBorder),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.bgElevated,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 0.5),
    listTileTheme: const ListTileThemeData(
      textColor: Colors.white,
      iconColor: AppColors.textSecondary,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.accent : AppColors.textMuted),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.accent.withOpacity(0.35) : AppColors.bgLight),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    iconTheme: const IconThemeData(color: AppColors.textSecondary),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
      bodySmall: TextStyle(color: AppColors.textMuted),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(primary: AppColors.primary, secondary: AppColors.accent),
  );
}
