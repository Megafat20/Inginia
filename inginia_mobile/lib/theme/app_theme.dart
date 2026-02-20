import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 🎨 Palette de Couleurs Premium
  static const Color primary = Color(0xFF4F46E5); // Indigo 600 - Moderne & Tech
  static const Color primaryDark = Color(0xFF3730A3); // Indigo 800
  static const Color primaryLight = Color(0xFF818CF8); // Indigo 400

  static const Color secondary = Color(
    0xFFF59E0B,
  ); // Amber 500 - Chaleur & Attention
  static const Color accent = Color(
    0xFF10B981,
  ); // Emerald 500 - Succès & Validation

  static const Color error = Color(0xFFEF4444); // Red 500

  static const Color background = Color(
    0xFFF8FAFC,
  ); // Slate 50 - Fond très clair
  static const Color surface = Colors.white;

  static const Color textDark = Color(0xFF1E293B); // Slate 800
  static const Color textLight = Color(0xFF64748B); // Slate 500

  // Additional text color getters for convenience
  static const Color textPrimary = Color(0xFF1E293B); // Slate 800
  static const Color textSecondary = Color(0xFF64748B); // Slate 500

  static TextStyle get headingStyle => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textDark,
  );

  // 🌙 Dark Mode Colors
  static const Color bgDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color textDarkPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color textDarkSecondary = Color(0xFF94A3B8); // Slate 400

  // 🖌️ Définition du Thème Global
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        error: const Color(0xFFEF4444),
      ),

      // 📝 Typographie (Inter pour la lisibilité, Outfit possible pour les titres)
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: textDark),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textLight),
      ),

      // 🔘 Boutons Modernes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Arrondi moderne
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      // 📦 Cartes (Card)
      /* cardTheme: const CardTheme(
        color: surface,
        elevation: 2,
        // shadowColor: Colors.black.withOpacity(0.1), // Peut causer des erreurs de type aussi parfois
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ), */

      // 🎨 Thème des icônes
      iconTheme: const IconThemeData(color: textDark, size: 24),

      // ⌨️ Champs de saisie (Input)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9), // Slate 100
        prefixIconColor: textLight,
        suffixIconColor: textLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),

      // 📱 AppBar propre
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  // 🌙 Thème Sombre Global
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        secondary: secondary,
        surface: surfaceDark,
        background: bgDark,
        error: const Color(0xFFEF4444),
      ),

      // 📝 Typographie Dark Mode
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textDarkPrimary,
            ),
            displayMedium: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textDarkPrimary,
            ),
            bodyLarge: GoogleFonts.inter(fontSize: 16, color: textDarkPrimary),
            bodyMedium: GoogleFonts.inter(
              fontSize: 14,
              color: textDarkSecondary,
            ),
          ),

      // 🔘 Boutons Dark Mode
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      // 📱 AppBar Dark Mode
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: textDarkPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDarkPrimary),
      ),

      // ⌨️ Input Dark Mode (CRITIQUE pour la visibilité)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B), // Fond sombre
        labelStyle: const TextStyle(
          color: textDarkSecondary,
        ), // Labels visibles
        hintStyle: const TextStyle(color: Color(0xFF64748B)), // Hints visibles
        prefixIconColor: textDarkSecondary,
        suffixIconColor: textDarkSecondary,

        // Texte dans les inputs sera BLANC (défini par textTheme)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),

      // 📦 Cartes Dark Mode
      cardTheme: const CardThemeData(
        color: surfaceDark,
        elevation: 4,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),

      // 🎨 Icônes Dark Mode
      iconTheme: const IconThemeData(color: textDarkPrimary, size: 24),

      // 🎭 Dialog Dark Mode
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // 📋 Bottom Sheet Dark Mode
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}
