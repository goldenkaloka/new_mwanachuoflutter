import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/constants/typography_constants.dart';

/// Creates the light theme for the application
///
/// Uses Plus Jakarta Sans as the primary font family and establishes
/// a comprehensive design system with proper text styles, button themes,
/// and component styles.
ThemeData lightTheme() {
  final base = ThemeData.light();

  return base.copyWith(
    brightness: Brightness.light,

    // ========================================
    // COLOR SCHEME
    // ========================================
    colorScheme: base.colorScheme.copyWith(
      primary: kPrimaryColor,
      primaryContainer: kPrimaryColorLight,
      secondary: kPrimaryColorDark,
      surface: kSurfaceColorLight,
      error: kErrorColor,
      onPrimary: kBackgroundColorDark,
      onSecondary: kBackgroundColorDark,
      onSurface: kTextPrimary,
      onError: Colors.white,
    ),

    scaffoldBackgroundColor: kBackgroundColorLight,

    // ========================================
    // TEXT THEME - Complete typography system
    // ========================================
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
      // Display styles (for large hero text)
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: AppTypography.fontSize8xl,
        fontWeight: AppTypography.extraBold,
        color: kTextPrimary,
        height: AppTypography.tightLineHeight,
        letterSpacing: AppTypography.tightSpacing,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: AppTypography.fontSize7xl,
        fontWeight: AppTypography.bold,
        color: kTextPrimary,
        height: AppTypography.tightLineHeight,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: AppTypography.fontSize6xl,
        fontWeight: AppTypography.semiBold,
        color: kTextPrimary,
        height: AppTypography.comfortableLineHeight,
      ),

      // Headline styles (for page titles, section headers)
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: AppTypography.fontSize5xl,
        fontWeight: AppTypography.bold,
        color: kTextPrimary,
        height: AppTypography.comfortableLineHeight,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: AppTypography.fontSize4xl,
        fontWeight: AppTypography.semiBold,
        color: kTextPrimary,
        height: AppTypography.comfortableLineHeight,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: AppTypography.fontSize3xl,
        fontWeight: AppTypography.semiBold,
        color: kTextPrimary,
        height: AppTypography.normalLineHeight,
      ),

      // Title styles (for card titles, list titles)
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: AppTypography.fontSize2xl,
        fontWeight: AppTypography.semiBold,
        color: kTextPrimary,
        height: AppTypography.relaxedLineHeight,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: AppTypography.fontSizeXl,
        fontWeight: AppTypography.medium,
        color: kTextPrimary,
        height: AppTypography.relaxedLineHeight,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: AppTypography.fontSizeLg,
        fontWeight: AppTypography.medium,
        color: kTextPrimary,
        height: AppTypography.relaxedLineHeight,
      ),

      // Body styles (for main content)
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: AppTypography.fontSize2xl,
        fontWeight: AppTypography.regular,
        color: kTextPrimary,
        height: AppTypography.openLineHeight,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: AppTypography.fontSizeLg,
        fontWeight: AppTypography.regular,
        color: kTextSecondary,
        height: AppTypography.openLineHeight,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: AppTypography.fontSizeMd,
        fontWeight: AppTypography.regular,
        color: kTextSecondary,
        height: AppTypography.relaxedLineHeight,
      ),

      // Label styles (for buttons, tabs, chips)
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: AppTypography.fontSizeLg,
        fontWeight: AppTypography.semiBold,
        color: kTextPrimary,
        height: AppTypography.normalLineHeight,
        letterSpacing: AppTypography.wideSpacing,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: AppTypography.fontSizeSm,
        fontWeight: AppTypography.medium,
        color: kTextPrimary,
        height: AppTypography.normalLineHeight,
        letterSpacing: AppTypography.wideSpacing,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: AppTypography.fontSizeXs,
        fontWeight: AppTypography.medium,
        color: kTextSecondary,
        height: AppTypography.normalLineHeight,
        letterSpacing: AppTypography.wideSpacing,
      ),
    ),

    // ========================================
    // BUTTON THEMES
    // ========================================

    // PRIMARY ELEVATED BUTTON (Main CTA)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: kBackgroundColorDark,
        backgroundColor: kPrimaryColor,
        disabledForegroundColor: kTextDisabled,
        disabledBackgroundColor: kBorderColor,
        elevation: kElevationNone, // Flat design
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: kBaseRadiusMd),
        padding: const EdgeInsets.symmetric(
          vertical: kSpacingLg,
          horizontal: kSpacing2xl,
        ),
        minimumSize: const Size(64, 48), // Accessibility: min 48px height
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: AppTypography.fontSize2xl,
          fontWeight: AppTypography.semiBold,
          letterSpacing: AppTypography.wideSpacing,
        ),
      ),
    ),

    // OUTLINED BUTTON (Secondary actions)
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimaryColor,
        disabledForegroundColor: kTextDisabled,
        side: const BorderSide(color: kPrimaryColor, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: kBaseRadiusMd),
        padding: const EdgeInsets.symmetric(
          vertical: kSpacingLg,
          horizontal: kSpacing2xl,
        ),
        minimumSize: const Size(64, 48),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: AppTypography.fontSize2xl,
          fontWeight: AppTypography.semiBold,
          letterSpacing: AppTypography.wideSpacing,
        ),
      ),
    ),

    // TEXT BUTTON (Tertiary/subtle actions)
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kPrimaryColor,
        disabledForegroundColor: kTextDisabled,
        padding: const EdgeInsets.symmetric(
          vertical: kSpacingMd,
          horizontal: kSpacingLg,
        ),
        minimumSize: const Size(48, 40),
        shape: RoundedRectangleBorder(borderRadius: kBaseRadiusSm),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: AppTypography.fontSizeLg,
          fontWeight: AppTypography.medium,
          letterSpacing: AppTypography.wideSpacing,
        ),
      ),
    ),

    // ========================================
    // COMPONENT THEMES
    // ========================================

    // Card theme
    cardTheme: CardThemeData(
      color: kSurfaceColorLight,
      elevation: kElevationNone,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusMd),
      ),
      margin: const EdgeInsets.all(kSpacingSm),
    ),

    // Divider theme
    dividerTheme: const DividerThemeData(
      color: kDividerColor,
      thickness: 1,
      space: 1,
    ),

    // Icon theme
    iconTheme: const IconThemeData(color: kTextSecondary, size: kIconSizeLg),

    // AppBar theme
    appBarTheme: AppBarTheme(
      backgroundColor: kBackgroundColorLight,
      foregroundColor: kTextPrimary,
      elevation: kElevationNone,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: AppTypography.fontSize4xl,
        fontWeight: AppTypography.semiBold,
        color: kTextPrimary,
      ),
      iconTheme: const IconThemeData(color: kTextPrimary, size: kIconSizeLg),
    ),

    // FloatingActionButton theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kPrimaryColor,
      foregroundColor: kBackgroundColorDark,
      elevation: kElevationMd,
      shape: CircleBorder(),
    ),

    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: kPrimaryColorLight.withValues(alpha: 0.2),
      selectedColor: kPrimaryColor,
      disabledColor: kBorderColor,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: AppTypography.fontSizeSm,
        fontWeight: AppTypography.medium,
        color: kTextPrimary,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: kSpacingMd,
        vertical: kSpacingSm,
      ),
      shape: RoundedRectangleBorder(borderRadius: kBaseRadiusFull),
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurfaceColorLight,
      contentPadding: const EdgeInsets.all(kSpacingLg),
      border: OutlineInputBorder(
        borderRadius: kBaseRadiusMd,
        borderSide: const BorderSide(color: kBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: kBaseRadiusMd,
        borderSide: const BorderSide(color: kBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: kBaseRadiusMd,
        borderSide: const BorderSide(color: kPrimaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: kBaseRadiusMd,
        borderSide: const BorderSide(color: kErrorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: kBaseRadiusMd,
        borderSide: const BorderSide(color: kErrorColor, width: 2),
      ),
      hintStyle: GoogleFonts.plusJakartaSans(
        color: kTextSecondary,
        fontWeight: AppTypography.regular,
      ),
      labelStyle: GoogleFonts.plusJakartaSans(
        color: kTextSecondary,
        fontWeight: AppTypography.medium,
      ),
    ),

    // SnackBar theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kBackgroundColorDark,
      contentTextStyle: GoogleFonts.plusJakartaSans(
        color: kTextPrimaryDark,
        fontSize: AppTypography.fontSizeLg,
      ),
      shape: RoundedRectangleBorder(borderRadius: kBaseRadiusMd),
      behavior: SnackBarBehavior.floating,
    ),

    // BottomSheet theme
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: kSurfaceColorLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusXl)),
      ),
      elevation: kElevationLg,
    ),
  );
}
