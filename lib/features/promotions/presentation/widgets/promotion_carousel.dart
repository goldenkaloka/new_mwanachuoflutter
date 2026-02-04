import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/features/promotions/domain/entities/promotion_entity.dart';
import 'package:mwanachuo/features/promotions/presentation/bloc/promotion_cubit.dart';
import 'package:mwanachuo/features/promotions/presentation/bloc/promotion_state.dart';
import 'package:mwanachuo/features/promotions/presentation/widgets/promotion_card.dart';

class PromotionCarousel extends StatefulWidget {
  const PromotionCarousel({super.key});

  @override
  State<PromotionCarousel> createState() => _PromotionCarouselState();
}

class _PromotionCarouselState extends State<PromotionCarousel> {
  int _currentPromotionPage = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PromotionCubit, PromotionState>(
      builder: (context, state) {
        if (state is PromotionInitial) {
          context.read<PromotionCubit>().loadActivePromotions();
          return _buildLoadingCarousel();
        }

        if (state is PromotionsLoading) {
          return _buildLoadingCarousel();
        }

        if (state is PromotionsLoaded) {
          if (state.promotions.isEmpty) {
            return const SizedBox.shrink();
          }

          final screenSize = ResponsiveBreakpoints.getScreenSize(context);
          return _buildCarousel(state.promotions, screenSize);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCarousel(
    List<PromotionEntity> promotions,
    ScreenSize screenSize,
  ) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: promotions.length,
          itemBuilder: (context, index, realIndex) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: PromotionCard(
                promotion: promotions[index],
                index: index,
                isActive: index == _currentPromotionPage,
              ),
            );
          },
          options: CarouselOptions(
            height: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 160.0,
              medium: 180.0,
              expanded: 220.0,
            ),
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: true,
            scrollDirection: Axis.horizontal,
            viewportFraction: 0.8,
            onPageChanged: (index, reason) {
              setState(() {
                _currentPromotionPage = index;
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(promotions.length, (index) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPromotionPage == index
                    ? PromotionCard
                          .promotionGradients[index %
                              PromotionCard.promotionGradients.length]
                          .colors
                          .first
                    : Colors.grey[700]!,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildLoadingCarousel() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
