import 'package:flutter/material.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/utils/responsive.dart';

/// A container that constrains content width and provides responsive padding
/// 
/// This widget ensures content doesn't stretch too wide on large screens
/// and provides appropriate padding based on screen size.
/// 
/// Example:
/// ```dart
/// Scaffold(
///   body: ResponsiveContainer(
///     child: Column(
///       children: [
///         // Your content here
///       ],
///     ),
///   ),
/// )
/// ```
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final bool centerContent;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.centerContent = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveBreakpoints.getScreenSize(context);
    
    // Default max widths for each breakpoint
    final effectiveMaxWidth = maxWidth ?? _getDefaultMaxWidth(screenSize);
    
    // Responsive padding
    final effectivePadding = padding ?? _getDefaultPadding(screenSize);
    
    Widget content = Padding(
      padding: effectivePadding,
      child: child,
    );

    if (centerContent) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: content,
        ),
      );
    } else {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: content,
      );
    }

    return content;
  }

  double _getDefaultMaxWidth(ScreenSize screenSize) {
    switch (screenSize) {
      case ScreenSize.compact:
        return double.infinity; // Full width on mobile
      case ScreenSize.medium:
        return 768; // Tablet max width
      case ScreenSize.expanded:
        return 1200; // Desktop max width
    }
  }

  EdgeInsets _getDefaultPadding(ScreenSize screenSize) {
    switch (screenSize) {
      case ScreenSize.compact:
        return const EdgeInsets.all(kSpacingLg); // 16px
      case ScreenSize.medium:
        return const EdgeInsets.all(kSpacingXl); // 20px
      case ScreenSize.expanded:
        return const EdgeInsets.all(kSpacing3xl); // 32px
    }
  }
}

/// A wrapper widget that provides consistent max-width constraints
/// 
/// Simpler than ResponsiveContainer - just constrains width without padding.
class ConstrainedContent extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ConstrainedContent({
    Key? key,
    required this.child,
    this.maxWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveBreakpoints.getScreenSize(context);
    final effectiveMaxWidth = maxWidth ?? _getDefaultMaxWidth(screenSize);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: child,
      ),
    );
  }

  double _getDefaultMaxWidth(ScreenSize screenSize) {
    switch (screenSize) {
      case ScreenSize.compact:
        return double.infinity;
      case ScreenSize.medium:
        return 768;
      case ScreenSize.expanded:
        return 1200;
    }
  }
}

/// A responsive grid that adjusts column count based on screen size
/// 
/// Provides a consistent grid layout that adapts to different screen sizes.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double? spacing;
  final double? runSpacing;
  final double? childAspectRatio;
  final int? compactColumns;
  final int? mediumColumns;
  final int? expandedColumns;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.spacing,
    this.runSpacing,
    this.childAspectRatio,
    this.compactColumns,
    this.mediumColumns,
    this.expandedColumns,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveBreakpoints.getScreenSize(context);
    final columnCount = _getColumnCount(screenSize);

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        childAspectRatio: childAspectRatio ?? 0.75,
        crossAxisSpacing: spacing ?? kSpacingLg,
        mainAxisSpacing: runSpacing ?? kSpacingLg,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  int _getColumnCount(ScreenSize screenSize) {
    switch (screenSize) {
      case ScreenSize.compact:
        return compactColumns ?? 2;
      case ScreenSize.medium:
        return mediumColumns ?? 3;
      case ScreenSize.expanded:
        return expandedColumns ?? 4;
    }
  }
}

/// A responsive padding widget that adjusts padding based on screen size
/// 
/// Provides consistent padding that scales with screen size.
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? compact;
  final EdgeInsets? medium;
  final EdgeInsets? expanded;

  const ResponsivePadding({
    Key? key,
    required this.child,
    this.compact,
    this.medium,
    this.expanded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveBreakpoints.getScreenSize(context);
    final padding = _getPadding(screenSize);

    return Padding(
      padding: padding,
      child: child,
    );
  }

  EdgeInsets _getPadding(ScreenSize screenSize) {
    switch (screenSize) {
      case ScreenSize.compact:
        return compact ?? const EdgeInsets.all(kSpacingLg);
      case ScreenSize.medium:
        return medium ?? const EdgeInsets.all(kSpacingXl);
      case ScreenSize.expanded:
        return expanded ?? const EdgeInsets.all(kSpacing3xl);
    }
  }
}

/// A responsive spacing widget that adjusts gap size based on screen size
class ResponsiveSpacing extends StatelessWidget {
  final double? compact;
  final double? medium;
  final double? expanded;
  final Axis axis;

  const ResponsiveSpacing({
    Key? key,
    this.compact,
    this.medium,
    this.expanded,
    this.axis = Axis.vertical,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveBreakpoints.getScreenSize(context);
    final spacing = _getSpacing(screenSize);

    return axis == Axis.vertical
        ? SizedBox(height: spacing)
        : SizedBox(width: spacing);
  }

  double _getSpacing(ScreenSize screenSize) {
    switch (screenSize) {
      case ScreenSize.compact:
        return compact ?? kSpacingLg;
      case ScreenSize.medium:
        return medium ?? kSpacingXl;
      case ScreenSize.expanded:
        return expanded ?? kSpacing2xl;
    }
  }
}

