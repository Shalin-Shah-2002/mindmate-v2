import 'package:flutter/material.dart';

class AppTheme {
  // Brand seed color (indigo/purple)
  static const Color seed = Color(0xFF6366F1);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8F9FB),
      cardColor: Colors.white,
      // Enhanced text theme for light mode
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Color(0xFF1A1D23),
          fontWeight: FontWeight.w300,
        ),
        displayMedium: TextStyle(
          color: Color(0xFF1A1D23),
          fontWeight: FontWeight.w300,
        ),
        displaySmall: TextStyle(
          color: Color(0xFF1A1D23),
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: TextStyle(
          color: Color(0xFF1A1D23),
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: TextStyle(
          color: Color(0xFF1A1D23),
          fontWeight: FontWeight.w400,
        ),
        headlineSmall: TextStyle(
          color: Color(0xFF1A1D23),
          fontWeight: FontWeight.w400,
        ),
        titleLarge: TextStyle(
          color: Color(0xFF1A1D23),
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          color: Color(0xFF1A1D23),
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: Color(0xFF4A5568),
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFF2D3748),
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF4A5568),
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: Color(0xFF718096),
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: Color(0xFF2D3748),
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: Color(0xFF4A5568),
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: Color(0xFF718096),
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1D23),
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black12,
        titleTextStyle: const TextStyle(
          color: Color(0xFF1A1D23),
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF4A5568), size: 24),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.primary.withOpacity(0.4)),
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Color(0xFF718096)),
        labelStyle: const TextStyle(color: Color(0xFF4A5568)),
        prefixIconColor: const Color(0xFF718096),
        suffixIconColor: const Color(0xFF718096),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: const Color(0xFF718096),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedIconTheme: const IconThemeData(size: 26),
        unselectedIconTheme: const IconThemeData(size: 24),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      dialogBackgroundColor: Colors.white,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2D3748),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        highlightElevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF7FAFC),
        selectedColor: colorScheme.primary.withOpacity(0.15),
        disabledColor: const Color(0xFFE2E8F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(
          color: Color(0xFF2D3748),
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 0.5),
      ),
      switchTheme: SwitchThemeData(
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary.withOpacity(0.6);
          }
          if (states.contains(MaterialState.disabled)) {
            return const Color(0xFFCBD5E0);
          }
          return const Color(0xFFE2E8F0);
        }),
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary;
          }
          if (states.contains(MaterialState.disabled)) {
            return const Color(0xFFA0AEC0);
          }
          return Colors.white;
        }),
        trackOutlineColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.transparent;
          }
          return const Color(0xFFCBD5E0);
        }),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.white,
        textColor: Color(0xFF2D3748),
        iconColor: Color(0xFF4A5568),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 0.5,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: const Color(0xFFE2E8F0),
        circularTrackColor: const Color(0xFFE2E8F0),
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0A0B0D),
      cardColor: const Color(0xFF1A1D23),
      // Enhanced text theme for dark mode
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Color(0xFFE1E4E8),
          fontWeight: FontWeight.w300,
        ),
        displayMedium: TextStyle(
          color: Color(0xFFE1E4E8),
          fontWeight: FontWeight.w300,
        ),
        displaySmall: TextStyle(
          color: Color(0xFFE1E4E8),
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: TextStyle(
          color: Color(0xFFE1E4E8),
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: TextStyle(
          color: Color(0xFFE1E4E8),
          fontWeight: FontWeight.w400,
        ),
        headlineSmall: TextStyle(
          color: Color(0xFFE1E4E8),
          fontWeight: FontWeight.w400,
        ),
        titleLarge: TextStyle(
          color: Color(0xFFE1E4E8),
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          color: Color(0xFFE1E4E8),
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: Color(0xFFB8BCC2),
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: Color(0xFFE1E4E8),
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFB8BCC2),
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: Color(0xFF8B949E),
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: Color(0xFFE1E4E8),
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: Color(0xFFB8BCC2),
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: Color(0xFF8B949E),
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: const Color(0xFFE1E4E8),
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black26,
        titleTextStyle: const TextStyle(
          color: Color(0xFFE1E4E8),
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        iconTheme: const IconThemeData(color: Color(0xFFE1E4E8), size: 24),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.primary.withOpacity(0.4)),
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF21262D),
        hintStyle: const TextStyle(color: Color(0xFF8B949E)),
        labelStyle: const TextStyle(color: Color(0xFFB8BCC2)),
        prefixIconColor: const Color(0xFF8B949E),
        suffixIconColor: const Color(0xFF8B949E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDA3633), width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF161B22),
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: const Color(0xFF8B949E),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedIconTheme: const IconThemeData(size: 26),
        unselectedIconTheme: const IconThemeData(size: 24),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      dialogBackgroundColor: const Color(0xFF21262D),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF21262D),
        contentTextStyle: const TextStyle(color: Color(0xFFE1E4E8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 6,
        focusElevation: 8,
        hoverElevation: 8,
        highlightElevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF21262D),
        selectedColor: colorScheme.primary.withOpacity(0.2),
        disabledColor: const Color(0xFF30363D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(
          color: Color(0xFFE1E4E8),
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: Color(0xFF30363D), width: 0.5),
      ),
      switchTheme: SwitchThemeData(
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary.withOpacity(0.6);
          }
          if (states.contains(MaterialState.disabled)) {
            return const Color(0xFF30363D);
          }
          return const Color(0xFF21262D);
        }),
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary;
          }
          if (states.contains(MaterialState.disabled)) {
            return const Color(0xFF8B949E);
          }
          return const Color(0xFFB8BCC2);
        }),
        trackOutlineColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.transparent;
          }
          return const Color(0xFF30363D);
        }),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Color(0xFF21262D),
        textColor: Color(0xFFE1E4E8),
        iconColor: Color(0xFFB8BCC2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF30363D),
        thickness: 0.5,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: const Color(0xFF30363D),
        circularTrackColor: const Color(0xFF30363D),
      ),
    );
  }
}
