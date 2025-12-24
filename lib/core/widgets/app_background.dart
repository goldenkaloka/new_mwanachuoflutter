import 'package:flutter/material.dart';

/// A reusable background widget that applies a subtle gradient
/// across the entire app for a cohesive, premium aesthetic.
///
/// Usage:
/// ```dart
/// Scaffold(
///   body: AppBackground(
///     child: YourContent(),
///   ),
/// )
/// ```
class AppBackground extends StatelessWidget {
  final Widget child;
  final bool? isDark;

  const AppBackground({super.key, required this.child, this.isDark});

  @override
  Widget build(BuildContext context) {
    final effectiveIsDarkMode =
        isDark ?? (Theme.of(context).brightness == Brightness.dark);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: effectiveIsDarkMode
              ? [
                  const Color(0xFF1A1A1A), // Dark top
                  const Color(0xFF0D0D0D), // Darker bottom
                ]
              : [
                  const Color(0xFFFAFAFA), // Very light gray top
                  const Color(0xFFF0F0F0), // Slightly darker gray bottom
                ],
        ),
      ),
      child: child,
    );
  }
}
