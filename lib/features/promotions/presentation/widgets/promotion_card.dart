import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';
import 'package:mwanachuo/features/promotions/domain/entities/promotion_entity.dart';
import 'package:mwanachuo/features/promotions/presentation/widgets/promotion_video_player.dart';

class PromotionCard extends StatefulWidget {
  final PromotionEntity promotion;
  final int index;
  final bool isActive;
  final double? width;
  final double? height;

  const PromotionCard({
    super.key,
    required this.promotion,
    required this.index,
    this.isActive = true,
    this.width,
    this.height,
  });

  @override
  State<PromotionCard> createState() => _PromotionCardState();
}

class _PromotionCardState extends State<PromotionCard>
    with TickerProviderStateMixin {
  late AnimationController _arrowController;
  late Animation<double> _arrowAnimation;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    // Arrow slide animation (Restored)
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _arrowAnimation = Tween<double>(begin: 0.0, end: 4.0).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );

    // Premium Button Shimmer (Glint effect)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _arrowController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  static final List<LinearGradient> promotionGradients = [
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.lightBlue.shade900, Colors.lightBlue.shade100],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.pink.shade900, Colors.pink.shade100],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.purple.shade900, Colors.purple.shade100],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [kPrimaryColorDark, kPrimaryColorLight],
    ),
  ];

  void _navigateToDetails(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/promotion-details',
      arguments: widget.promotion.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardWidth =
        widget.width ??
        (MediaQuery.of(context).size.width -
            (ResponsiveBreakpoints.responsiveHorizontalPadding(context) * 2));
    final cardHeight =
        widget.height ??
        ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 280.0,
          medium: 320.0,
          expanded: 380.0,
        );

    final colorIndex = widget.index % promotionGradients.length;
    final gradient = promotionGradients[colorIndex];

    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          // STRICT FLAT DESIGN: No box shadow
        ),
        child: Column(
          children: [
            // 1. Featured Image/Video Section
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16.0),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.promotion.type == 'video' &&
                        widget.promotion.videoUrl != null)
                      PromotionVideoPlayer(
                        videoUrl: widget.promotion.videoUrl!,
                        thumbnailUrl: widget.promotion.imageUrl,
                        isPlaying: widget.isActive,
                      )
                    else if (widget.promotion.imageUrl != null)
                      NetworkImageWithFallback(
                        imageUrl: widget.promotion.imageUrl!,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(decoration: BoxDecoration(gradient: gradient)),

                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          widget.promotion.title,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Info Section (Logo + Details + Button)
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 12.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Seller/Brand Logo - Flat Design
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[200],
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                        child: NetworkImageWithFallback(
                          imageUrl: widget.promotion.sellerAvatarUrl ?? '',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.promotion.sellerName ?? 'Mwanachuo Partner',
                            style: GoogleFonts.plusJakartaSans(
                              color: isDarkMode
                                  ? Colors.white
                                  : Colors.grey[800],
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.promotion.description,
                            style: GoogleFonts.plusJakartaSans(
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: 12,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Promoted',
                            style: GoogleFonts.plusJakartaSans(
                              color: kPrimaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Action Button with Refined Shimmer
                    AnimatedBuilder(
                      animation: _shimmerAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: const [
                                kPrimaryColor,
                                kPrimaryColor,
                                Colors.white24,
                                kPrimaryColor,
                                kPrimaryColor,
                              ],
                              stops: [
                                0.0,
                                _shimmerAnimation.value - 0.2,
                                _shimmerAnimation.value,
                                _shimmerAnimation.value + 0.2,
                                1.0,
                              ],
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _navigateToDetails(context),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.promotion.buttonText.isNotEmpty
                                          ? widget.promotion.buttonText
                                          : 'View Detail',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // RESTORED Arrow Animation
                                    AnimatedBuilder(
                                      animation: _arrowAnimation,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(
                                            _arrowAnimation.value,
                                            0,
                                          ),
                                          child: child,
                                        );
                                      },
                                      child: const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 14,
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
