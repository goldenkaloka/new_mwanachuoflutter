import 'package:flutter/material.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';

class NetworkImageWithFallback extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;

  const NetworkImageWithFallback({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // Handle empty or invalid URLs
    final uri = Uri.tryParse(imageUrl);
    final isValidUrl =
        imageUrl.isNotEmpty &&
        uri != null &&
        uri.hasAbsolutePath &&
        (uri.scheme == 'http' || uri.scheme == 'https');

    if (!isValidUrl) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: kPrimaryColor.withValues(alpha: 0.3),
            borderRadius: borderRadius,
          ),
          child: Icon(
            Icons.person,
            color: Colors.white.withValues(alpha: 0.7),
            size: (width != null && height != null)
                ? (width! < height! ? width! * 0.3 : height! * 0.3)
                : 24,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        // Suppress error logs by catching errors silently
        errorBuilder: (context, error, stackTrace) {
          // Return a placeholder container instead of throwing errors
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.3),
              borderRadius: borderRadius,
            ),
            child: Icon(
              Icons.image_not_supported,
              color: Colors.white.withValues(alpha: 0.7),
              size: (width != null && height != null)
                  ? (width! < height! ? width! * 0.3 : height! * 0.3)
                  : 24,
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.3),
              borderRadius: borderRadius,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          );
        },
        // Add frameBuilder to handle loading states better
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: child,
          );
        },
      ),
    );
  }
}
