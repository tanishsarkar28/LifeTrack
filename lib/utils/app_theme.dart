import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/data_providers.dart';

class AppTheme {
  static ThemeData getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.midnightBlack:
        return _midnightBlackTheme;
      case AppThemeType.forestGreen:
        return _forestGreenTheme;
      case AppThemeType.neonCyberpunk:
        return _neonCyberpunkTheme;
      case AppThemeType.darkBlue:
      default:
        return _darkBlueTheme;
    }
  }

  static ThemeData get _darkBlueTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0F1A),
      primaryColor: const Color(0xFF7C5CFF),
      cardColor: const Color(0xFF151D36),
      canvasColor: const Color(0xFF141B33),
      dialogBackgroundColor: const Color(0xFF1A223E),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F1525),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white70),
        titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF7C5CFF),
        secondary: Color(0xFF03DAC6),
        surface: Color(0xFF131A2E),
        background: Color(0xFF0C1220),
        error: Color(0xFFCF6679),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onBackground: Colors.white,
        onError: Colors.black,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF141B2F),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF111727),
        selectedItemColor: Color(0xFF7C5CFF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C5CFF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF7C5CFF),
        foregroundColor: Colors.white,
      ),
      tabBarTheme: TabBarThemeData(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF7C5CFF).withOpacity(0.16),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
      ),
    );
  }
  static ThemeData get _midnightBlackTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      primaryColor: Colors.white,
      cardColor: const Color(0xFF121212),
      canvasColor: const Color(0xFF0F0F0F),
      dialogBackgroundColor: const Color(0xFF1E1E1E),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        secondary: Colors.grey,
        surface: Color(0xFF121212),
        error: Colors.redAccent,
        onPrimary: Colors.black,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        color: const Color(0xFF121212),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get _forestGreenTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF09140B),
      primaryColor: const Color(0xFF2ECC71),
      cardColor: const Color(0xFF112315),
      canvasColor: const Color(0xFF122014),
      dialogBackgroundColor: const Color(0xFF162D1A),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0D1C10),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white70),
        titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF2ECC71),
        secondary: Color(0xFF27AE60),
        surface: Color(0xFF112315),
        error: Colors.redAccent,
        onPrimary: Colors.black,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        color: const Color(0xFF112315),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0D1C10),
        selectedItemColor: Color(0xFF2ECC71),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get _neonCyberpunkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF05051A),
      primaryColor: const Color(0xFFFF007F),
      cardColor: const Color(0xFF120C29),
      canvasColor: const Color(0xFF15102D),
      dialogBackgroundColor: const Color(0xFF1B143B),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0B071F),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white70),
        titleTextStyle: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF00FFCC)),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF007F),
        secondary: Color(0xFF00FFCC),
        surface: Color(0xFF120C29),
        error: Colors.redAccent,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        color: const Color(0xFF120C29),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0B071F),
        selectedItemColor: Color(0xFFFF007F),
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
