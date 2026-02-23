import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/utils/responsive.dart';

/// Sticky action bar that appears when scrolling past hero image
class StickyActionBar extends StatelessWidget {
  final String price;
  final String? priceSubtitle;
  final String actionButtonText;
  final VoidCallback onActionTap;
  final VoidCallback? onSmsTap;
  final List<Widget>? trailingActions;

  const StickyActionBar({
    super.key,
    required this.price,
    this.priceSubtitle,
    required this.actionButtonText,
    required this.onActionTap,
    this.onSmsTap,
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  if (priceSubtitle != null)
                    Text(
                      priceSubtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            // Contact Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // SMS Button
                if (onSmsTap != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: onSmsTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          foregroundColor: Colors.blue,
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: SvgPicture.asset(
                          'assets/svgs/call-receive-svgrepo-com.svg',
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            Colors.blue,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                // WhatsApp Button
                ElevatedButton.icon(
                  onPressed: onActionTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: SvgPicture.asset(
                    'assets/svgs/whatsapp-color-svgrepo-com.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: Text(
                    actionButtonText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            // Trailing actions
            if (trailingActions != null) ...trailingActions!,
          ],
        ),
      ),
    );
  }
}
