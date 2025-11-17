import 'package:flutter/material.dart';

enum ScreenSize { compact, medium, expanded }

class ResponsiveBreakpoints {
  static const double compactBreakpoint = 600;
  static const double mediumBreakpoint = 1200;

  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < compactBreakpoint) {
      return ScreenSize.compact;
    } else if (width < mediumBreakpoint) {
      return ScreenSize.medium;
    } else {
      return ScreenSize.expanded;
    }
  }

  static bool isCompact(BuildContext context) => getScreenSize(context) == ScreenSize.compact;
  static bool isMedium(BuildContext context) => getScreenSize(context) == ScreenSize.medium;
  static bool isExpanded(BuildContext context) => getScreenSize(context) == ScreenSize.expanded;

  static T responsiveValue<T>(
    BuildContext context, {
    required T compact,
    T? medium,
    T? expanded,
  }) {
    final screenSize = getScreenSize(context);
    if (screenSize == ScreenSize.expanded && expanded != null) {
      return expanded;
    } else if (screenSize == ScreenSize.medium && medium != null) {
      return medium;
    } else {
      return compact;
    }
  }

  static double responsiveHorizontalPadding(BuildContext context) {
    return responsiveValue(
      context,
      compact: 16.0,
      medium: 20.0,
      expanded: 32.0,
    );
  }

  static int responsiveGridColumns(BuildContext context) {
    return responsiveValue(
      context,
      compact: 2,
      medium: 3,
      expanded: 4,
    );
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize screenSize) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = ResponsiveBreakpoints.getScreenSize(context);
        return builder(context, screenSize);
      },
    );
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final currentMaxWidth = maxWidth ?? ResponsiveBreakpoints.responsiveValue<double>(
      context,
      compact: double.infinity,
      medium: 900.0,
      expanded: 1200.0,
    );

    return Center(
      child: Container(
        padding: padding,
        constraints: BoxConstraints(maxWidth: currentMaxWidth),
        child: child,
      ),
    );
  }
}


