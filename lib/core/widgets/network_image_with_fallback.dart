import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/widgets/shimmer_loading.dart';

class NetworkImageWithFallback extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;
  final bool usePlaceholder;
  final int? maxWidth;
  final int? maxHeight;

  const NetworkImageWithFallback({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
    this.usePlaceholder = true,
    this.maxWidth,
    this.maxHeight,
  });

  /// Optimize image URL for Supabase Storage (if applicable)
  /// Adds resize parameters to reduce image size
  /// Optimize image URL for Supabase Storage (if applicable)
  /// Note: Transformation requires specific bucket configuration or Pro plan
  String _getOptimizedImageUrl(String url) {
    // Temporarily disabled transformation as it might cause 403 errors if not configured
    return url;
  }

  @override
  Widget build(BuildContext context) {
    // Trim URL and relaxed check: just check if it's not empty and starts with http/https
    final trimmedUrl = imageUrl.trim();
    final isValidUrl =
        trimmedUrl.isNotEmpty &&
        (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://'));

    if (!isValidUrl) {
      return _buildPlaceholder();
    }

    // Get optimized URL (currently returns raw URL)
    final optimizedUrl = _getOptimizedImageUrl(trimmedUrl);

    // Helper function to safely convert double to int
    int? safeToInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) {
        // Check if value is finite and not NaN before converting
        if (!value.isFinite || value.isNaN) return null;
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed;
      }
      return null;
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: optimizedUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        // Memory cache configuration - use higher resolution for better quality
        memCacheWidth:
            maxWidth ??
            (safeToInt(width) != null ? (safeToInt(width)! * 2) : null),
        memCacheHeight:
            maxHeight ??
            (safeToInt(height) != null ? (safeToInt(height)! * 2) : null),
        // Placeholder while loading
        placeholder: usePlaceholder
            ? (context, url) => ShimmerLoading(
                width: width ?? double.infinity,
                height: height ?? double.infinity,
                borderRadius: borderRadius,
              )
            : null,
        // Error widget
        errorWidget: (context, url, error) => _buildErrorPlaceholder(),
        // Fade in animation
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
      ),
    );
  }

  /// Calculate a safe icon size that is always finite
  double _calculateIconSize(double? width, double? height) {
    if (width != null && height != null) {
      // Ensure both values are finite before using them
      if (width.isFinite && height.isFinite) {
        final calculatedSize = (width < height ? width * 0.3 : height * 0.3);
        // Ensure the result is finite and within reasonable bounds
        if (calculatedSize.isFinite &&
            calculatedSize > 0 &&
            calculatedSize < 1000) {
          return calculatedSize;
        }
      }
    }
    // Default safe size
    return 24.0;
  }

  Widget _buildPlaceholder() {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kPrimaryColor.withValues(alpha: 0.2),
              kPrimaryColor.withValues(alpha: 0.4),
            ],
          ),
          borderRadius: borderRadius,
        ),
        child: Icon(
          Icons.image_outlined,
          color: Colors.white.withValues(alpha: 0.9),
          size: _calculateIconSize(width, height),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.withValues(alpha: 0.3),
            Colors.grey.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.image_not_supported,
        color: Colors.white.withValues(alpha: 0.9),
        size: _calculateIconSize(width, height),
      ),
    );
  }
}
