import 'package:flutter/material.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/utils/responsive.dart';

/// Sticky action bar that appears when scrolling past hero image
class StickyActionBar extends StatelessWidget {
  final String price;
  final String? priceSubtitle;
  final String actionButtonText;
  final VoidCallback onActionTap;
  final List<Widget>? trailingActions;

  const StickyActionBar({
    super.key,
    required this.price,
    this.priceSubtitle,
    required this.actionButtonText,
    required this.onActionTap,
    this.trailingActions,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isCompact = ResponsiveBreakpoints.isCompact(context);

    if (!isCompact) {
      return const SizedBox.shrink(); // Only show on mobile
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Price section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  if (priceSubtitle != null)
                    Text(
                      priceSubtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            // Action button
            ElevatedButton(
              onPressed: onActionTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(actionButtonText),
            ),
            // Trailing actions
            if (trailingActions != null) ...trailingActions!,
          ],
        ),
      ),
    );
  }
}
