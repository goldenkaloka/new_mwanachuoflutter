import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';

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
class ProductCard extends StatefulWidget {
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
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    // Tap animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Subtle float animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _shadowAnimation = Tween<double>(begin: 2.0, end: 4.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -_floatAnimation.value),
            child: GestureDetector(
              onTapDown: (_) => _controller.forward(),
              onTapUp: (_) {
                _controller.reverse();
                widget.onTap();
              },
              onTapCancel: () => _controller.reverse(),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    color: kSurfaceColorLight,
                    borderRadius: BorderRadius.circular(kRadiusSm),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withValues(alpha: 0.08),
                        blurRadius: _shadowAnimation.value,
                        offset: Offset(0, _shadowAnimation.value / 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      Expanded(
                        flex: isSmallScreen ? 3 : 2,
                        child: Hero(
                          tag: 'product_${widget.imageUrl}',
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(kRadiusSm),
                            ),
                            child: NetworkImageWithFallback(
                              imageUrl: widget.imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(kRadiusSm),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : kSpacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              widget.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontSize: isSmallScreen ? 13 : null,
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isSmallScreen ? 2 : kSpacingXs),
                            // Price
                            Text(
                              widget.price,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 12 : null,
                                  ),
                            ),
                            if (widget.showCategory &&
                                widget.category != null) ...[
                              SizedBox(height: isSmallScreen ? 2 : kSpacingXs),
                              Row(
                                children: [
                                  if (widget.showRating &&
                                      widget.rating != null) ...[
                                    Icon(
                                      Icons.star,
                                      size: isSmallScreen ? 12 : kIconSizeSm,
                                      color: kWarningColor,
                                    ),
                                    SizedBox(
                                      width: isSmallScreen ? 2 : kSpacingXs,
                                    ),
                                    Flexible(
                                      child: Text(
                                        '${widget.rating!.toStringAsFixed(1)}${widget.reviewCount != null ? ' (${widget.reviewCount})' : ''}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontSize: isSmallScreen
                                                  ? 10
                                                  : null,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                  if (widget.showCategory &&
                                      widget.category != null) ...[
                                    if (widget.showRating &&
                                        widget.rating != null)
                                      const Spacer(),
                                    Flexible(
                                      child: Text(
                                        widget.category!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: kTextSecondary,
                                              fontSize: isSmallScreen
                                                  ? 10
                                                  : null,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
              ),
            ),
          );
        },
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
    return RepaintBoundary(
      child: GestureDetector(
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
              Hero(
                tag: 'service_$imageUrl',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(kRadiusSm),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    memCacheWidth: 180,
                    memCacheHeight: 180,
                    placeholder: (context, url) => Container(
                      width: 90,
                      height: 90,
                      color: kBorderColor,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            kPrimaryColor,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 90,
                      height: 90,
                      color: kBorderColor,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: kIconSizeLg,
                          color: kTextSecondary,
                        ),
                      ),
                    ),
                    fadeInDuration: const Duration(milliseconds: 200),
                  ),
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
      ), // RepaintBoundary closing
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? kSurfaceColorDark : kSurfaceColorLight,
            borderRadius: BorderRadius.circular(kRadiusSm),
            // Removed boxShadow to remove shadows
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image - takes more space on small screens
              Expanded(
                flex: isSmallScreen ? 3 : 2,
                child: Hero(
                  tag: 'accommodation_$imageUrl',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(kRadiusSm),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      memCacheWidth: 600,
                      maxWidthDiskCache: 800,
                      placeholder: (context, url) => Container(
                        color: isDarkMode ? kBorderColorDark : kBorderColor,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              kPrimaryColor,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDarkMode ? kBorderColorDark : kBorderColor,
                        child: const Center(
                          child: Icon(
                            Icons.home_outlined,
                            size: kIconSize2xl,
                            color: kTextSecondary,
                          ),
                        ),
                      ),
                      fadeInDuration: const Duration(milliseconds: 200),
                    ),
                  ),
                ),
              ),

              // Content - takes less space on small screens
              Expanded(
                flex: isSmallScreen ? 2 : 3,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 6 : kSpacingSm,
                      vertical: isSmallScreen ? 4 : kSpacingSm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontSize: isSmallScreen ? 13 : null,
                                height: 1.2,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Text(
                          price,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: const Color(0xFF078829),
                                fontWeight: FontWeight.w700,
                                fontSize: isSmallScreen ? 13 : null,
                                height: 1.2,
                              ),
                        ),
                        if (location != null ||
                            bedrooms != null ||
                            bathrooms != null) ...[
                          SizedBox(height: isSmallScreen ? 3 : 4),
                          Row(
                            children: [
                              if (location != null) ...[
                                Icon(
                                  Icons.location_on_outlined,
                                  size: isSmallScreen ? 11 : kIconSizeSm,
                                  color: kTextSecondary,
                                ),
                                SizedBox(width: isSmallScreen ? 2 : kSpacingXs),
                                Flexible(
                                  child: Text(
                                    location!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontSize: isSmallScreen ? 9 : null,
                                          height: 1.2,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              if (bedrooms != null || bathrooms != null) ...[
                                if (location != null)
                                  SizedBox(
                                    width: isSmallScreen ? 3 : kSpacingXs,
                                  ),
                                if (bedrooms != null) ...[
                                  Icon(
                                    Icons.bed_outlined,
                                    size: isSmallScreen ? 11 : kIconSizeSm,
                                    color: kTextSecondary,
                                  ),
                                  SizedBox(
                                    width: isSmallScreen ? 2 : kSpacingXs,
                                  ),
                                  Text(
                                    '$bedrooms',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontSize: isSmallScreen ? 9 : null,
                                          height: 1.2,
                                        ),
                                  ),
                                ],
                                if (bathrooms != null) ...[
                                  if (bedrooms != null)
                                    SizedBox(
                                      width: isSmallScreen ? 3 : kSpacingXs,
                                    ),
                                  Icon(
                                    Icons.bathtub_outlined,
                                    size: isSmallScreen ? 11 : kIconSizeSm,
                                    color: kTextSecondary,
                                  ),
                                  SizedBox(
                                    width: isSmallScreen ? 2 : kSpacingXs,
                                  ),
                                  Text(
                                    '$bathrooms',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontSize: isSmallScreen ? 9 : null,
                                          height: 1.2,
                                        ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ), // RepaintBoundary closing
    );
  }
}
