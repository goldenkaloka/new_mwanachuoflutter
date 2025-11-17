import 'package:flutter/material.dart';

// ========================================
// PRIMARY COLORS
// ========================================
const Color kPrimaryColor = Color(0xFF95F9C3); // Main brand green
const Color kPrimaryColorDark = Color(0xFF6BD89F); // Darker shade
const Color kPrimaryColorLight = Color(0xFFB6FCDA); // Lighter shade

// ========================================
// BACKGROUND COLORS
// ========================================
const Color kBackgroundColorLight = Color(0xFFF8FAFC); // Light mode background
const Color kBackgroundColorDark = Color(0xFF102218); // Dark mode background
const Color kSurfaceColorLight = Color(0xFFFFFFFF); // Cards in light mode
const Color kSurfaceColorDark = Color(0xFF1C2F26); // Cards in dark mode

// ========================================
// TEXT COLORS
// ========================================
const Color kTextPrimary = Color(0xFF1E293B); // Primary text (light mode)
const Color kTextSecondary = Color(0xFF475569); // Secondary text (light mode)
const Color kTextTertiary = Color(0xFF64748B); // Tertiary text (light mode)
const Color kTextDisabled = Color(0xFF94A3B8); // Disabled text (light mode)

const Color kTextPrimaryDark = Color(0xFFFFFFFF); // Primary text (dark mode)
const Color kTextSecondaryDark = Color(0xFFCBD5E1); // Secondary text (dark mode)
const Color kTextTertiaryDark = Color(0xFF94A3B8); // Tertiary text (dark mode)

// ========================================
// SEMANTIC COLORS
// ========================================
const Color kSuccessColor = Color(0xFF10B981); // Success green
const Color kSuccessColorLight = Color(0xFFD1FAE5); // Success background
const Color kWarningColor = Color(0xFFF59E0B); // Warning orange
const Color kWarningColorLight = Color(0xFFFEF3C7); // Warning background
const Color kErrorColor = Color(0xFFEF4444); // Error red
const Color kErrorColorLight = Color(0xFFFEE2E2); // Error background
const Color kInfoColor = Color(0xFF3B82F6); // Info blue
const Color kInfoColorLight = Color(0xFFDBEAFE); // Info background

// ========================================
// BORDER COLORS
// ========================================
const Color kBorderColor = Color(0xFFE2E8F0); // Light mode borders
const Color kBorderColorDark = Color(0xFF334155); // Dark mode borders
const Color kDividerColor = Color(0xFFE2E8F0); // Dividers
const Color kDividerColorDark = Color(0xFF334155); // Dark mode dividers

// ========================================
// INTERACTIVE COLORS
// ========================================
const Color kHoverColor = Color(0xFFF1F5F9); // Hover state
const Color kPressedColor = Color(0xFFE2E8F0); // Pressed state
const Color kSelectedColor = Color(0xFFDCFCE7); // Selected state
const Color kFocusColor = Color(0xFF95F9C3); // Focus state

// ========================================
// SPECIAL COLORS
// ========================================
const Color kOnlineStatusColor = Color(0xFF10B981); // Green for online
const Color kOfflineStatusColor = Color(0xFF94A3B8); // Gray for offline
const Color kUnreadBadgeColor = Color(0xFFEF4444); // Red badge for unread

// ========================================
// GRADIENTS
// ========================================
const LinearGradient kPrimaryGradient = LinearGradient(
  colors: [Color(0xFF95F9C3), Color(0xFF6BD89F)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kCardGradient = LinearGradient(
  colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kDarkCardGradient = LinearGradient(
  colors: [Color(0xFF1C2F26), Color(0xFF102218)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ========================================
// SHADOWS
// ========================================
/// Small shadow - for subtle elevation (buttons, chips)
final List<BoxShadow> kShadowSm = [
  BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 4,
    offset: const Offset(0, 1),
  ),
];

/// Medium shadow - for cards, containers
final List<BoxShadow> kShadowMd = [
  BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 8,
    offset: const Offset(0, 2),
  ),
];

/// Large shadow - for modals, dialogs
final List<BoxShadow> kShadowLg = [
  BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 16,
    offset: const Offset(0, 4),
  ),
];

/// Extra large shadow - for floating elements
final List<BoxShadow> kShadowXl = [
  BoxShadow(
    color: Colors.black.withOpacity(0.15),
    blurRadius: 24,
    offset: const Offset(0, 8),
  ),
];

// ========================================
// SPACING (4pt Grid System)
// ========================================
const double kSpacingXs = 4.0;   // Tiny gaps (icon-text spacing)
const double kSpacingSm = 8.0;   // Small gaps (line spacing, chip gaps)
const double kSpacingMd = 12.0;  // Medium gaps (card content padding)
const double kSpacingLg = 16.0;  // Default gaps (section padding)
const double kSpacingXl = 20.0;  // Large gaps (between sections)
const double kSpacing2xl = 24.0; // XL gaps (major sections)
const double kSpacing3xl = 32.0; // 2XL gaps (screen padding desktop)
const double kSpacing4xl = 40.0; // 3XL gaps (large separations)
const double kSpacing5xl = 48.0; // 4XL gaps (hero sections)

// ========================================
// BORDER RADIUS
// ========================================
const double kRadiusXs = 4.0;
const double kRadiusSm = 8.0;
const double kRadiusMd = 12.0;
const double kRadiusLg = 16.0;
const double kRadiusXl = 20.0;
const double kRadius2xl = 24.0;
const double kRadiusFull = 9999.0;

final BorderRadius kBaseRadiusXs = BorderRadius.circular(kRadiusXs);
final BorderRadius kBaseRadiusSm = BorderRadius.circular(kRadiusSm);
final BorderRadius kBaseRadiusMd = BorderRadius.circular(kRadiusMd);
final BorderRadius kBaseRadiusLg = BorderRadius.circular(kRadiusLg);
final BorderRadius kBaseRadiusXl = BorderRadius.circular(kRadiusXl);
final BorderRadius kBaseRadius2xl = BorderRadius.circular(kRadius2xl);
final BorderRadius kBaseRadiusFull = BorderRadius.circular(kRadiusFull);

// Legacy support - keep for backward compatibility
final kBaseRadius = kBaseRadiusLg; // Default 16px radius

// ========================================
// ICON SIZES
// ========================================
const double kIconSizeXs = 12.0;  // Tiny icons (badges, inline indicators)
const double kIconSizeSm = 16.0;  // Small icons (inline with text)
const double kIconSizeMd = 20.0;  // Medium icons (buttons, list items)
const double kIconSizeLg = 24.0;  // Large icons (FAB, AppBar, primary actions)
const double kIconSizeXl = 32.0;  // XL icons (larger touch targets)
const double kIconSize2xl = 48.0; // 2XL icons (empty states, features)
const double kIconSize3xl = 64.0; // 3XL icons (hero sections, errors)

// ========================================
// ELEVATION LEVELS
// ========================================
const double kElevationNone = 0.0;
const double kElevationSm = 2.0;
const double kElevationMd = 4.0;
const double kElevationLg = 8.0;
const double kElevationXl = 16.0;

// ========================================
// ANIMATION DURATIONS
// ========================================
const Duration kAnimationFast = Duration(milliseconds: 150);
const Duration kAnimationNormal = Duration(milliseconds: 300);
const Duration kAnimationSlow = Duration(milliseconds: 500);

// ========================================
// OPACITY LEVELS
// ========================================
const double kOpacityDisabled = 0.38;
const double kOpacityMedium = 0.60;
const double kOpacityHigh = 0.87;
const double kOpacityFull = 1.0;
