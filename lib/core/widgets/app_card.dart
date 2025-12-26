import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';

/// Card size options
enum AppCardSize { small, medium, large }

/// Card style options
enum AppCardStyle { elevated, outlined, filled }

/// A standardized card widget that ensures consistent styling across the app
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
    const isDarkMode = false;
    final cardPadding = padding ?? _getPadding(size);
    final bgColor = backgroundColor ?? kSurfaceColorLight;
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
        return const EdgeInsets.all(kSpacingMd);
      case AppCardSize.medium:
        return const EdgeInsets.all(kSpacingLg);
      case AppCardSize.large:
        return const EdgeInsets.all(kSpacingXl);
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

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
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return AnimatedBuilder(
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(kRadiusSm),
                  ),
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
                    AspectRatio(
                      aspectRatio: 1.0,
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
                    Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : kSpacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          const SizedBox(height: 4),
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
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (widget.showRating &&
                                    widget.rating != null) ...[
                                  const Icon(
                                    Icons.star,
                                    size: 12,
                                    color: kWarningColor,
                                  ),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      '${widget.rating!.toStringAsFixed(1)}${widget.reviewCount != null ? ' (${widget.reviewCount})' : ''}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontSize: isSmallScreen ? 10 : null,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                if (widget.showRating && widget.rating != null)
                                  const Spacer(),
                                Flexible(
                                  child: Text(
                                    widget.category!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: kTextSecondary,
                                          fontSize: isSmallScreen ? 10 : null,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String id;
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
    required this.id,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? kSurfaceColorDark : kSurfaceColorLight,
          borderRadius: BorderRadius.circular(kRadiusMd),
          border: Border.all(
            color: isDarkMode ? kBorderColorDark : kBorderColor,
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section on Left
            SizedBox(
              width: 100,
              height: 100,
              child: Hero(
                tag: 'service_$id',
                child: NetworkImageWithFallback(
                  imageUrl: imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: kSpacingMd),
            // Text Section on Right
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (category != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        category!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: kTextSecondary),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          price,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: const Color(0xFF078829),
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                        ),
                        Flexible(
                          child: Text(
                            '/$priceType',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: kTextSecondary, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (providerName != null) ...[
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: kTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              providerName!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: 11,
                                    color: kTextSecondary,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (location != null) ...[
                          if (providerName != null) const SizedBox(width: 12),
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: kTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              location!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: 11,
                                    color: kTextSecondary,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8, right: 8),
              child: Icon(Icons.chevron_right, color: kTextSecondary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

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
          border: Border.all(
            color: isDarkMode ? kBorderColorDark : kBorderColor,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Section
            AspectRatio(
              aspectRatio: 1.0, // Switched to 1:1 for better balance in Masonry
              child: Hero(
                tag: 'accommodation_$imageUrl',
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
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
                ),
              ),
            ),
            // Info Section
            Padding(
              padding: const EdgeInsets.all(kSpacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        price,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF078829),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                      ),
                      Flexible(
                        child: Text(
                          '/$priceType',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: kTextSecondary, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  if (location != null ||
                      bedrooms != null ||
                      bathrooms != null) ...[
                    const SizedBox(height: 10),
                    if (location != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: kTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: 11,
                                    color: kTextSecondary,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      children: [
                        if (bedrooms != null) ...[
                          const Icon(
                            Icons.bed_outlined,
                            size: 14,
                            color: kTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$bedrooms',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontSize: 11, color: kTextSecondary),
                          ),
                        ],
                        if (bathrooms != null) ...[
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.bathtub_outlined,
                            size: 14,
                            color: kTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$bathrooms',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontSize: 11, color: kTextSecondary),
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
