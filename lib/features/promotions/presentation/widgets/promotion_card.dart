import 'package:flutter/material.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/core/widgets/network_image_with_fallback.dart';
import 'package:mwanachuo/features/promotions/domain/entities/promotion_entity.dart';
import 'package:mwanachuo/features/promotions/presentation/widgets/animated_promotion_text.dart';
import 'package:mwanachuo/features/promotions/presentation/widgets/promotion_video_player.dart';

class PromotionCard extends StatelessWidget {
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

  static final List<LinearGradient> promotionGradients = [
    // Light Blue
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.lightBlue.shade900, Colors.lightBlue.shade100],
    ),
    // Pink
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.pink.shade900, Colors.pink.shade100],
    ),
    // Purple
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.purple.shade900, Colors.purple.shade100],
    ),
    // Teal
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.teal.shade900, Colors.teal.shade100],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cardWidth =
        width ??
        ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 400.0,
          medium: 480.0,
          expanded: 580.0,
        );
    final cardHeight =
        height ??
        ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 140.0,
          medium: 160.0,
          expanded: 200.0,
        );

    final colorIndex = index % promotionGradients.length;
    final gradient = promotionGradients[colorIndex];

    Color textColor;
    switch (colorIndex) {
      case 0:
        textColor = Colors.amberAccent;
        break;
      case 1:
        textColor = Colors.white;
        break;
      case 2:
        textColor = Colors.lightGreenAccent;
        break;
      case 3:
        textColor = Colors.yellowAccent;
        break;
      default:
        textColor = Colors.white;
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/promotion-details',
        arguments: promotion.id,
      ),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (promotion.type == 'video' && promotion.videoUrl != null)
                PromotionVideoPlayer(
                  videoUrl: promotion.videoUrl!,
                  isPlaying: isActive,
                )
              else if (promotion.imageUrl != null)
                NetworkImageWithFallback(
                  imageUrl: promotion.imageUrl!,
                  fit: BoxFit.cover,
                ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        gradient.colors.first.withValues(alpha: 0.8),
                        gradient.colors.first.withValues(alpha: 0.2),
                      ],
                      stops: const [0.3, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedPromotionText(
                      text: promotion.title,
                      fontSize: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 18.0,
                        medium: 20.0,
                        expanded: 24.0,
                      ),
                      fontWeight: FontWeight.bold,
                      maxLines: 1,
                      textColor: textColor,
                      shouldAnimate: isActive,
                    ),
                    const SizedBox(height: 4.0),
                    AnimatedPromotionText(
                      text: promotion.subtitle,
                      fontSize: ResponsiveBreakpoints.responsiveValue(
                        context,
                        compact: 12.0,
                        medium: 14.0,
                        expanded: 16.0,
                      ),
                      fontWeight: FontWeight.w500,
                      maxLines: 2,
                      textColor: textColor.withValues(alpha: 0.9),
                      shouldAnimate: isActive,
                      delay: const Duration(milliseconds: 500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
