import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';

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
  String _getOptimizedImageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    // Check if it's a Supabase Storage URL
    if (uri.host.contains('supabase') || uri.host.contains('storage')) {
      final params = <String, String>{};

      // Add resize parameters if dimensions are specified
      if (maxWidth != null) params['width'] = maxWidth.toString();
      if (maxHeight != null) params['height'] = maxHeight.toString();

      // Add quality parameter for better compression
      if (params.isNotEmpty) {
        params['quality'] = '80'; // 80% quality for good balance
        params['resize'] = 'cover'; // Maintain aspect ratio
      }

      if (params.isEmpty) return url;

      // Build optimized URL with query parameters
      return uri
          .replace(queryParameters: {...uri.queryParameters, ...params})
          .toString();
    }

    return url;
  }

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
      return _buildPlaceholder();
    }

    // Get optimized URL
    final optimizedUrl = _getOptimizedImageUrl(imageUrl);

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: optimizedUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        // Memory cache configuration
        memCacheWidth: maxWidth ?? width?.toInt(),
        memCacheHeight: maxHeight ?? height?.toInt(),
        // Placeholder while loading
        placeholder: usePlaceholder
            ? (context, url) => Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: borderRadius,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
              )
            : null,
        // Error widget
        errorWidget: (context, url, error) => _buildErrorPlaceholder(),
        // Fade in animation
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
        // Cache configuration
        cacheKey: optimizedUrl, // Use optimized URL as cache key
        maxWidthDiskCache: maxWidth ?? 1000, // Limit disk cache size
        maxHeightDiskCache: maxHeight ?? 1000,
      ),
    );
  }

  Widget _buildPlaceholder() {
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

  Widget _buildErrorPlaceholder() {
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
  }
}
