import 'package:flutter/material.dart';
import 'package:mwanachuo/core/utils/responsive.dart';

/// Wrapper for sliver sections with consistent padding
class SliverSection extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool useResponsivePadding;

  const SliverSection({
    super.key,
    required this.child,
    this.padding,
    this.useResponsivePadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final sectionPadding =
        padding ??
        (useResponsivePadding
            ? EdgeInsets.symmetric(
                horizontal: ResponsiveBreakpoints.responsiveHorizontalPadding(
                  context,
                ),
                vertical: 24,
              )
            : const EdgeInsets.all(24));

    return SliverPadding(
      padding: sectionPadding,
      sliver: SliverToBoxAdapter(child: child),
    );
  }
}


