import 'package:flutter/material.dart';

/// Typography constants for consistent font styling across the app
/// 
/// This class provides standardized font weights, letter spacing,
/// and line heights to ensure visual consistency.
class AppTypography {
  // ========================================
  // FONT WEIGHTS
  // ========================================
  
  /// Light weight (300) - Use sparingly for large display text
  static const FontWeight light = FontWeight.w300;
  
  /// Regular weight (400) - Default for body text
  static const FontWeight regular = FontWeight.w400;
  
  /// Medium weight (500) - For emphasis in body text, subtitles
  static const FontWeight medium = FontWeight.w500;
  
  /// Semi-bold weight (600) - For headings, titles, important text
  static const FontWeight semiBold = FontWeight.w600;
  
  /// Bold weight (700) - For strong emphasis, primary headings
  static const FontWeight bold = FontWeight.w700;
  
  /// Extra-bold weight (800) - For hero text, display headings
  static const FontWeight extraBold = FontWeight.w800;
  
  // ========================================
  // LETTER SPACING
  // ========================================
  
  /// Tight spacing (-0.5) - For large display text to improve readability
  static const double tightSpacing = -0.5;
  
  /// Normal spacing (0.0) - Default for most text
  static const double normalSpacing = 0.0;
  
  /// Wide spacing (0.5) - For buttons, labels, uppercase text
  static const double wideSpacing = 0.5;
  
  /// Extra-wide spacing (1.0) - For all-caps headings, emphasis
  static const double extraWideSpacing = 1.0;
  
  // ========================================
  // LINE HEIGHTS (Height multipliers)
  // ========================================
  
  /// Tight line height (1.2) - For large headings, display text
  static const double tightLineHeight = 1.2;
  
  /// Comfortable line height (1.3) - For headings
  static const double comfortableLineHeight = 1.3;
  
  /// Normal line height (1.4) - For titles, labels
  static const double normalLineHeight = 1.4;
  
  /// Relaxed line height (1.5) - For body text, better readability
  static const double relaxedLineHeight = 1.5;
  
  /// Open line height (1.6) - For long-form content, paragraphs
  static const double openLineHeight = 1.6;
  
  // ========================================
  // FONT SIZES
  // ========================================
  
  /// Font size for tiny text (11sp) - Captions, legal text
  static const double fontSizeXs = 11.0;
  
  /// Font size for small text (12sp) - Captions, labels
  static const double fontSizeSm = 12.0;
  
  /// Font size for small body text (13sp) - Secondary body text
  static const double fontSizeMd = 13.0;
  
  /// Font size for medium text (14sp) - Body text, descriptions
  static const double fontSizeLg = 14.0;
  
  /// Font size for regular text (15sp) - Titles, list items
  static const double fontSizeXl = 15.0;
  
  /// Font size for large text (16sp) - Primary body, large titles
  static const double fontSize2xl = 16.0;
  
  /// Font size for headings (18sp) - Section headings
  static const double fontSize3xl = 18.0;
  
  /// Font size for large headings (20sp) - Page titles
  static const double fontSize4xl = 20.0;
  
  /// Font size for display text (24sp) - Hero headings
  static const double fontSize5xl = 24.0;
  
  /// Font size for large display (28sp) - Feature headings
  static const double fontSize6xl = 28.0;
  
  /// Font size for extra large display (32sp) - Hero sections
  static const double fontSize7xl = 32.0;
  
  /// Font size for huge display (36sp) - Splash, onboarding
  static const double fontSize8xl = 36.0;
}

/// Predefined text styles for common use cases
/// 
/// These provide quick access to commonly used text style combinations.
class AppTextStyles {
  // ========================================
  // HEADING STYLES
  // ========================================
  
  /// Hero heading - Large, bold, attention-grabbing (36sp, extra-bold)
  static const TextStyle heroHeading = TextStyle(
    fontSize: AppTypography.fontSize8xl,
    fontWeight: AppTypography.extraBold,
    height: AppTypography.tightLineHeight,
    letterSpacing: AppTypography.tightSpacing,
  );
  
  /// Display heading - Large feature headings (32sp, bold)
  static const TextStyle displayHeading = TextStyle(
    fontSize: AppTypography.fontSize7xl,
    fontWeight: AppTypography.bold,
    height: AppTypography.tightLineHeight,
  );
  
  /// Large heading - Main page titles (24sp, bold)
  static const TextStyle largeHeading = TextStyle(
    fontSize: AppTypography.fontSize5xl,
    fontWeight: AppTypography.bold,
    height: AppTypography.comfortableLineHeight,
  );
  
  /// Medium heading - Section titles (20sp, semi-bold)
  static const TextStyle mediumHeading = TextStyle(
    fontSize: AppTypography.fontSize4xl,
    fontWeight: AppTypography.semiBold,
    height: AppTypography.comfortableLineHeight,
  );
  
  /// Small heading - Subsection titles (18sp, semi-bold)
  static const TextStyle smallHeading = TextStyle(
    fontSize: AppTypography.fontSize3xl,
    fontWeight: AppTypography.semiBold,
    height: AppTypography.normalLineHeight,
  );
  
  // ========================================
  // TITLE STYLES
  // ========================================
  
  /// Large title - Card titles, prominent labels (16sp, semi-bold)
  static const TextStyle largeTitle = TextStyle(
    fontSize: AppTypography.fontSize2xl,
    fontWeight: AppTypography.semiBold,
    height: AppTypography.relaxedLineHeight,
  );
  
  /// Medium title - List titles, form labels (15sp, medium)
  static const TextStyle mediumTitle = TextStyle(
    fontSize: AppTypography.fontSizeXl,
    fontWeight: AppTypography.medium,
    height: AppTypography.relaxedLineHeight,
  );
  
  /// Small title - Secondary titles, chips (14sp, medium)
  static const TextStyle smallTitle = TextStyle(
    fontSize: AppTypography.fontSizeLg,
    fontWeight: AppTypography.medium,
    height: AppTypography.relaxedLineHeight,
  );
  
  // ========================================
  // BODY STYLES
  // ========================================
  
  /// Large body - Primary content text (16sp, regular)
  static const TextStyle largeBody = TextStyle(
    fontSize: AppTypography.fontSize2xl,
    fontWeight: AppTypography.regular,
    height: AppTypography.openLineHeight,
  );
  
  /// Medium body - Standard body text (14sp, regular)
  static const TextStyle mediumBody = TextStyle(
    fontSize: AppTypography.fontSizeLg,
    fontWeight: AppTypography.regular,
    height: AppTypography.openLineHeight,
  );
  
  /// Small body - Secondary text, descriptions (13sp, regular)
  static const TextStyle smallBody = TextStyle(
    fontSize: AppTypography.fontSizeMd,
    fontWeight: AppTypography.regular,
    height: AppTypography.relaxedLineHeight,
  );
  
  // ========================================
  // LABEL STYLES
  // ========================================
  
  /// Large label - Button text, tab labels (14sp, semi-bold, wide spacing)
  static const TextStyle largeLabel = TextStyle(
    fontSize: AppTypography.fontSizeLg,
    fontWeight: AppTypography.semiBold,
    height: AppTypography.normalLineHeight,
    letterSpacing: AppTypography.wideSpacing,
  );
  
  /// Medium label - Small button text, badges (12sp, medium, wide spacing)
  static const TextStyle mediumLabel = TextStyle(
    fontSize: AppTypography.fontSizeSm,
    fontWeight: AppTypography.medium,
    height: AppTypography.normalLineHeight,
    letterSpacing: AppTypography.wideSpacing,
  );
  
  /// Small label - Tiny labels, status indicators (11sp, medium, wide spacing)
  static const TextStyle smallLabel = TextStyle(
    fontSize: AppTypography.fontSizeXs,
    fontWeight: AppTypography.medium,
    height: AppTypography.normalLineHeight,
    letterSpacing: AppTypography.wideSpacing,
  );
  
  // ========================================
  // SPECIAL STYLES
  // ========================================
  
  /// Caption - Fine print, metadata (12sp, regular)
  static const TextStyle caption = TextStyle(
    fontSize: AppTypography.fontSizeSm,
    fontWeight: AppTypography.regular,
    height: AppTypography.relaxedLineHeight,
  );
  
  /// Overline - Category labels, timestamps (11sp, medium, extra-wide, uppercase)
  static const TextStyle overline = TextStyle(
    fontSize: AppTypography.fontSizeXs,
    fontWeight: AppTypography.medium,
    height: AppTypography.normalLineHeight,
    letterSpacing: AppTypography.extraWideSpacing,
  );
  
  /// Button - Standard button text (16sp, semi-bold, wide)
  static const TextStyle button = TextStyle(
    fontSize: AppTypography.fontSize2xl,
    fontWeight: AppTypography.semiBold,
    letterSpacing: AppTypography.wideSpacing,
  );
  
  /// Link - Hyperlink text (14sp, medium, underline)
  static const TextStyle link = TextStyle(
    fontSize: AppTypography.fontSizeLg,
    fontWeight: AppTypography.medium,
    decoration: TextDecoration.underline,
  );
}

