import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';

/// Custom in-app notification banner shown when push notification arrives in foreground
class InAppNotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;
  final Duration displayDuration;
  final IconData icon;
  final Color? iconColor;

  const InAppNotificationBanner({
    super.key,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.onTap,
    this.onDismiss,
    this.displayDuration = const Duration(seconds: 4),
    this.icon = Icons.notifications,
    this.iconColor,
  });

  @override
  State<InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();

  /// Show in-app notification banner
  static void show(
    BuildContext context, {
    required String title,
    required String body,
    String? imageUrl,
    required VoidCallback onTap,
    Duration displayDuration = const Duration(seconds: 4),
    IconData icon = Icons.notifications,
    Color? iconColor,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: InAppNotificationBanner(
          title: title,
          body: body,
          imageUrl: imageUrl,
          onTap: onTap,
          onDismiss: () => overlayEntry.remove(),
          displayDuration: displayDuration,
          icon: icon,
          iconColor: iconColor,
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _InAppNotificationBannerState extends State<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Slide in
    _controller.forward();

    // Auto dismiss after duration
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () {
                _dismiss();
                widget.onTap();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? kBackgroundColorDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      _dismiss();
                      widget.onTap();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Icon or Image
                          if (widget.imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.imageUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildIcon(isDarkMode),
                              ),
                            )
                          else
                            _buildIcon(isDarkMode),

                          const SizedBox(width: 12),

                          // Title and Body
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : kBackgroundColorDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.body,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : kTextSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Dismiss button
                          IconButton(
                            onPressed: _dismiss,
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: isDarkMode
                                  ? Colors.white54
                                  : kTextSecondary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(bool isDarkMode) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: (widget.iconColor ?? kPrimaryColor).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        widget.icon,
        color: widget.iconColor ?? kPrimaryColor,
        size: 24,
      ),
    );
  }
}
