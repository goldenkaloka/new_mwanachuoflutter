import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Core Colors extracted from the Tailwind config
const Color _kPrimaryColor = Color(0xFF95F9C3); // Primary: #95f9c3
const Color _kBackgroundColorLight = Color(
  0xFFF8FAFC,
); // Light Background: #f8fafc
const Color _kBackgroundColorDark = Color(0xFF102218); // Dark Background
const Color _kTextPrimary = Color(0xFF1E293B); // Dark text for light mode
const Color _kTextSecondary = Color(0xFF475569); // Secondary gray text
const Color _kBorderColor = Color(0xFFE2E8F0); // Input border color

final _kBaseRadius = BorderRadius.circular(16.0); // Default 1rem radius

ThemeData lightTheme() {
  final base = ThemeData.light();
  return base.copyWith(
    brightness: Brightness.light,
    // Define the primary color and other colors
    colorScheme: base.colorScheme.copyWith(
      primary: _kPrimaryColor,
      surface: _kBackgroundColorLight,
      onSurface: _kTextPrimary,
      secondary: _kTextSecondary,
    ),
    scaffoldBackgroundColor: _kBackgroundColorLight,
    // Use Plus Jakarta Sans for all text
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        color: _kTextPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 32,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        color: _kTextPrimary,
        fontSize: 16,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(color: _kTextSecondary),
    ),
    // Customize button styles
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: _kBackgroundColorDark,
        backgroundColor: _kPrimaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ), // full rounded
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        minimumSize: const Size(double.infinity, 56), // h-14
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.015,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(15),
      border: OutlineInputBorder(
        borderRadius: _kBaseRadius,
        borderSide: const BorderSide(color: _kBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: _kBaseRadius,
        borderSide: const BorderSide(color: _kBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: _kBaseRadius,
        borderSide: BorderSide(
          color: _kPrimaryColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      hintStyle: GoogleFonts.plusJakartaSans(
        color: _kTextSecondary.withValues(alpha: 0.7),
        fontWeight: FontWeight.normal,
      ),
    ),
  );
}

ThemeData darkTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    brightness: Brightness.dark,
    colorScheme: base.colorScheme.copyWith(
      primary: _kPrimaryColor,
      surface: _kBackgroundColorDark,
      onSurface: Colors.white,
      secondary: Colors.grey.shade400,
    ),
    scaffoldBackgroundColor: _kBackgroundColorDark,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 32,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        color: Colors.white,
        fontSize: 16,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: Colors.grey.shade300,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: _kBackgroundColorDark,
        backgroundColor: _kPrimaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9999),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        minimumSize: const Size(double.infinity, 56),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.015,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E382A), // Dark slate-800 equivalent
      contentPadding: const EdgeInsets.all(15),
      border: OutlineInputBorder(
        borderRadius: _kBaseRadius,
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: _kBaseRadius,
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: _kBaseRadius,
        borderSide: BorderSide(
          color: _kPrimaryColor.withValues(alpha: 0.8),
          width: 2,
        ),
      ),
      hintStyle: GoogleFonts.plusJakartaSans(
        color: Colors.grey.shade500,
        fontWeight: FontWeight.normal,
      ),
    ),
  );
}

