import 'package:flutter/material.dart';

/// Sticky header for sliver lists
class SliverStickyHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget child;

  const SliverStickyHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.backgroundColor,
    this.textColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        backgroundColor ?? (isDarkMode ? Colors.grey[900]! : Colors.white);
    final txtColor = textColor ?? (isDarkMode ? Colors.white : Colors.black87);

    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeaderDelegate(
            title: title,
            icon: icon,
            trailing: trailing,
            backgroundColor: bgColor,
            textColor: txtColor,
          ),
        ),
        child,
      ],
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  final Color backgroundColor;
  final Color textColor;

  _StickyHeaderDelegate({
    required this.title,
    this.icon,
    this.trailing,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return title != oldDelegate.title ||
        icon != oldDelegate.icon ||
        backgroundColor != oldDelegate.backgroundColor ||
        textColor != oldDelegate.textColor;
  }
}
