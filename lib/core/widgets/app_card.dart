import 'package:flutter/material.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';

/// Card size options
enum AppCardSize { small, medium, large }

/// Card style options
enum AppCardStyle { elevated, outlined, filled }

/// A standardized card widget that ensures consistent styling across the app
///
/// This widget provides three sizes (small, medium, large) and three styles
/// (elevated, outlined, filled) to maintain visual consistency.
///
/// Example:
/// ```dart
/// AppCard(
///   onTap: () => navigateToDetails(),
///   child: Column(
///     children: [
///       Text('Card Title'),
///       Text('Card Description'),
///     ],
///   ),
/// )
/// ```
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final AppCardSize size;
  final AppCardStyle style;
  final Color? backgroundColor;
  final double? borderRadius;
  final List<BoxShadow>? customShadow;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.size = AppCardSize.medium,
    this.style = AppCardStyle.elevated,
    this.backgroundColor,
    this.borderRadius,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    // Force light theme
    final isDarkMode = false;

    // Determine padding based on size
    final cardPadding = padding ?? _getPadding(size);

    // Determine colors
    final bgColor = backgroundColor ?? kSurfaceColorLight;

    // Determine shadow/border based on style
    final decoration = _getDecoration(style, isDarkMode, bgColor);

    final card = Container(
      decoration: decoration,
      padding: cardPadding,
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? kRadiusMd),
        child: card,
      );
    }

    return card;
  }

  EdgeInsets _getPadding(AppCardSize size) {
    switch (size) {
      case AppCardSize.small:
        return const EdgeInsets.all(kSpacingMd); // 12px
      case AppCardSize.medium:
        return const EdgeInsets.all(kSpacingLg); // 16px
      case AppCardSize.large:
        return const EdgeInsets.all(kSpacingXl); // 20px
    }
  }

  BoxDecoration _getDecoration(AppCardStyle style, bool isDark, Color bgColor) {
    switch (style) {
      case AppCardStyle.elevated:
        return BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius ?? kRadiusMd),
          boxShadow: customShadow ?? kShadowMd,
        );
      case AppCardStyle.outlined:
        return BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius ?? kRadiusMd),
          border: Border.all(color: kBorderColor, width: 1),
        );
      case AppCardStyle.filled:
        return BoxDecoration(
          color: kPrimaryColorLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(borderRadius ?? kRadiusMd),
        );
    }
  }
}

/// A specialized card for displaying product information
///
/// Provides a consistent layout for product images, titles, prices, and ratings.
/// Uses the AppCard as a base with customized content layout.
class ProductCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String? category;
  final double? rating;
  final int? reviewCount;
  final VoidCallback onTap;
  final bool showRating;
  final bool showCategory;

  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    this.category,
    this.rating,
    this.reviewCount,
    required this.onTap,
    this.showRating = true,
    this.showCategory = true,
  });

  @override
  Widget build(BuildContext context) {
    // Force light theme
    final isDarkMode = false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kSurfaceColorLight,
          borderRadius: BorderRadius.circular(kRadiusMd),
          // Removed boxShadow to remove shadows
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(kRadiusMd),
                ),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: kBorderColor,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: kIconSize2xl,
                          color: kTextSecondary,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: kBorderColor,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: kPrimaryColor,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(kSpacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: kSpacingXs),

                  // Price
                  Text(
                    price,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(
                        0xFF078829,
                      ), // Match active state color
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  // Rating & Category
                  if ((showRating && rating != null) ||
                      (showCategory && category != null)) ...[
                    const SizedBox(height: kSpacingXs),
                    Row(
                      children: [
                        if (showRating && rating != null) ...[
                          const Icon(
                            Icons.star,
                            size: kIconSizeSm,
                            color: kWarningColor,
                          ),
                          const SizedBox(width: kSpacingXs),
                          Text(
                            '${rating!.toStringAsFixed(1)}${reviewCount != null ? ' ($reviewCount)' : ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (showCategory && category != null) ...[
                          if (showRating && rating != null) const Spacer(),
                          Text(
                            category!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A specialized card for displaying service information
class ServiceCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String priceType;
  final String? category;
  final String? providerName;
  final String? location;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.priceType,
    this.category,
    this.providerName,
    this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Force light theme
    final isDarkMode = false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kSurfaceColorLight,
          borderRadius: BorderRadius.circular(kRadiusMd),
          // Removed boxShadow to remove shadows
        ),
        padding: const EdgeInsets.all(kSpacingMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(kRadiusSm),
              child: Image.network(
                imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 90,
                    height: 90,
                    color: isDarkMode ? kBorderColorDark : kBorderColor,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: kIconSizeLg,
                        color: kTextSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: kSpacingMd),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (category != null) ...[
                    const SizedBox(height: kSpacingXs),
                    Text(
                      category!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: kSpacingXs),
                  Text(
                    price,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(
                        0xFF078829,
                      ), // Match active state color
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: kSpacingSm),
                  Row(
                    children: [
                      if (providerName != null) ...[
                        const Icon(
                          Icons.person_outline,
                          size: kIconSizeSm,
                          color: kTextSecondary,
                        ),
                        const SizedBox(width: kSpacingXs),
                        Flexible(
                          child: Text(
                            providerName!,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (location != null) ...[
                        if (providerName != null)
                          const SizedBox(width: kSpacingMd),
                        const Icon(
                          Icons.location_on_outlined,
                          size: kIconSizeSm,
                          color: kTextSecondary,
                        ),
                        const SizedBox(width: kSpacingXs),
                        Flexible(
                          child: Text(
                            location!,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A specialized card for displaying accommodation information
class AccommodationCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String price;
  final String priceType;
  final String? location;
  final int? bedrooms;
  final int? bathrooms;
  final VoidCallback onTap;

  const AccommodationCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.priceType,
    this.location,
    this.bedrooms,
    this.bathrooms,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? kSurfaceColorDark : kSurfaceColorLight,
          borderRadius: BorderRadius.circular(kRadiusMd),
          // Removed boxShadow to remove shadows
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(kRadiusMd),
                ),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isDarkMode ? kBorderColorDark : kBorderColor,
                      child: const Center(
                        child: Icon(
                          Icons.home_outlined,
                          size: kIconSize2xl,
                          color: kTextSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(kSpacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: kSpacingXs),
                  Text(
                    price,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(
                        0xFF078829,
                      ), // Match active state color
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (location != null ||
                      bedrooms != null ||
                      bathrooms != null) ...[
                    const SizedBox(height: kSpacingSm),
                    Row(
                      children: [
                        if (location != null) ...[
                          const Icon(
                            Icons.location_on_outlined,
                            size: kIconSizeSm,
                            color: kTextSecondary,
                          ),
                          const SizedBox(width: kSpacingXs),
                          Flexible(
                            child: Text(
                              location!,
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (bedrooms != null || bathrooms != null) ...[
                          if (location != null)
                            const SizedBox(width: kSpacingMd),
                          if (bedrooms != null) ...[
                            const Icon(
                              Icons.bed_outlined,
                              size: kIconSizeSm,
                              color: kTextSecondary,
                            ),
                            const SizedBox(width: kSpacingXs),
                            Text(
                              '$bedrooms',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          if (bathrooms != null) ...[
                            if (bedrooms != null)
                              const SizedBox(width: kSpacingMd),
                            const Icon(
                              Icons.bathtub_outlined,
                              size: kIconSizeSm,
                              color: kTextSecondary,
                            ),
                            const SizedBox(width: kSpacingXs),
                            Text(
                              '$bathrooms',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
