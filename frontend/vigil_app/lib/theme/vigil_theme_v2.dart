import 'package:flutter/material.dart';

/// Premium Futuristic Theme V2 for Vigil.
/// 
/// Design language: Cybersecurity meets luxury.
/// - Deep space navy backgrounds with subtle star-field gradients
/// - Neon cyan/teal primary with electric glow effects
/// - Holographic shimmer accents
/// - Glassmorphism cards with depth and refraction
/// - Cinematic gradients with multiple color stops
/// - Premium typography with letter-spacing
class VigilThemeV2 {
  // ═══════════════════════════════════════════════════════════
  // BRAND COLORS — Deep Space + Neon Safety Palette
  // ═══════════════════════════════════════════════════════════

  // Backgrounds (deep space)
  static const Color spaceBlack = Color(0xFF030712);
  static const Color deepNavy = Color(0xFF0A0E21);
  static const Color darkNavy = Color(0xFF0F1629);
  static const Color surfaceDark = Color(0xFF141B2D);
  static const Color cardBase = Color(0xFF1A2236);
  static const Color cardElevated = Color(0xFF1F2A40);

  // Primary neon palette
  static const Color neonCyan = Color(0xFF00F5FF);
  static const Color electricBlue = Color(0xFF0EA5E9);
  static const Color holoCyan = Color(0xFF67E8F9);
  static const Color tealGlow = Color(0xFF2DD4BF);
  static const Color emeraldPulse = Color(0xFF34D399);

  // Accent colors
  static const Color violetNeon = Color(0xFF8B5CF6);
  static const Color fuchsiaPulse = Color(0xFFD946EF);
  static const Color amberAlert = Color(0xFFFBBF24);
  static const Color roseEmergency = Color(0xFFF43F5E);
  static const Color crimsonDanger = Color(0xFFDC2626);

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF475569);

  // Borders & Dividers
  static const Color borderSubtle = Color(0xFF1E293B);
  static const Color borderGlow = Color(0xFF0EA5E9);
  static const Color dividerColor = Color(0xFF1E293B);

  // ═══════════════════════════════════════════════════════════
  // GRADIENTS — Cinematic multi-stop gradients
  // ═══════════════════════════════════════════════════════════

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [spaceBlack, deepNavy, Color(0xFF050A18)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A2236), Color(0xFF0F1629)],
  );

  static const LinearGradient neonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonCyan, electricBlue, tealGlow],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient holoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonCyan, violetNeon, fuchsiaPulse],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [roseEmergency, crimsonDanger, Color(0xFF7F1D1D)],
  );

  static const LinearGradient shieldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonCyan, emeraldPulse],
  );

  static const LinearGradient cardGlassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x15FFFFFF), Color(0x05FFFFFF)],
  );

  // ═══════════════════════════════════════════════════════════
  // BOX SHADOWS — Neon glow effects
  // ═══════════════════════════════════════════════════════════

  static List<BoxShadow> neonGlow(Color color, {double intensity = 0.3}) => [
    BoxShadow(
      color: color.withOpacity(intensity),
      blurRadius: 20,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: color.withOpacity(intensity * 0.5),
      blurRadius: 40,
      spreadRadius: -10,
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: neonCyan.withOpacity(0.03),
      blurRadius: 30,
      spreadRadius: -5,
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];

  // ═══════════════════════════════════════════════════════════
  // TEXT STYLES — Premium typography
  // ═══════════════════════════════════════════════════════════

  static const TextStyle headingXL = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle headingLG = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle headingMD = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0,
    height: 1.3,
  );

  static const TextStyle bodyLG = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySM = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textMuted,
    letterSpacing: 0.5,
  );

  static const TextStyle labelBrand = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: neonCyan,
    letterSpacing: 1.5,
  );

  // ═══════════════════════════════════════════════════════════
  // THEME DATA — Material Theme
  // ═══════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: spaceBlack,
      primaryColor: neonCyan,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: tealGlow,
        tertiary: violetNeon,
        surface: cardBase,
        error: roseEmergency,
        onPrimary: spaceBlack,
        onSecondary: spaceBlack,
        onSurface: textPrimary,
        onError: textPrimary,
        outline: borderSubtle,
      ),
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: neonCyan, size: 22),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonCyan,
          foregroundColor: spaceBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: neonCyan, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: roseEmergency, width: 1),
        ),
        labelStyle: const TextStyle(color: textMuted, fontSize: 14),
        hintStyle: TextStyle(color: textMuted.withOpacity(0.6), fontSize: 14),
        prefixIconColor: neonCyan,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      cardTheme: CardTheme(
        color: cardBase,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: borderSubtle, width: 0.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF080C1A),
        selectedItemColor: neonCyan,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 0.5,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return neonCyan;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return neonCyan.withOpacity(0.25);
          return borderSubtle;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: neonCyan,
        linearTrackColor: borderSubtle,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardElevated,
        contentTextStyle: const TextStyle(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
