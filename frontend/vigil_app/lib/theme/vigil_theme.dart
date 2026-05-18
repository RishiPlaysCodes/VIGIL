import 'package:flutter/material.dart';

/// Premium dark navy / cyan safety theme for Vigil
class VigilTheme {
  // Brand Colors
  static const Color deepNavy = Color(0xFF0A0E21);
  static const Color darkNavy = Color(0xFF111328);
  static const Color cardDark = Color(0xFF1A1F3A);
  static const Color cardGlass = Color(0x331A1F3A);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color cyanGlow = Color(0xFF00B8D4);
  static const Color teal = Color(0xFF00BFA5);
  static const Color emerald = Color(0xFF00E676);
  static const Color alertRed = Color(0xFFFF1744);
  static const Color warningOrange = Color(0xFFFF9100);
  static const Color purple = Color(0xFF7C4DFF);
  static const Color textWhite = Color(0xFFF5F5F5);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFF2A2F4A);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, teal],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E2340), Color(0xFF151930)],
  );

  static const LinearGradient alertGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [alertRed, Color(0xFFD50000)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deepNavy, Color(0xFF050714)],
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepNavy,
      primaryColor: cyan,
      colorScheme: const ColorScheme.dark(
        primary: cyan,
        secondary: teal,
        surface: cardDark,
        error: alertRed,
        onPrimary: deepNavy,
        onSecondary: deepNavy,
        onSurface: textWhite,
        onError: textWhite,
      ),
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textWhite,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: cyan),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cyan,
          foregroundColor: deepNavy,
          elevation: 8,
          shadowColor: cyan.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cyan,
          side: const BorderSide(color: cyan, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: alertRed, width: 1),
        ),
        labelStyle: const TextStyle(color: textGrey),
        hintStyle: TextStyle(color: textGrey.withOpacity(0.6)),
        prefixIconColor: cyan,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      cardTheme: CardTheme(
        color: cardDark,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkNavy,
        selectedItemColor: cyan,
        unselectedItemColor: textGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 20,
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cyan;
          return textGrey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cyan.withOpacity(0.3);
          return divider;
        }),
      ),
    );
  }
}
