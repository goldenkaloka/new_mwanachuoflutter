import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/widgets/shimmer_loading.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/accommodations/domain/entities/accommodation_constants.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_bloc.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_event.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_state.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_criteria_entity.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_entity.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_type.dart';
import 'package:mwanachuo/features/shared/recommendations/presentation/cubit/recommendation_cubit.dart';
import 'package:mwanachuo/features/shared/recommendations/presentation/cubit/recommendation_state.dart';
import 'package:mwanachuo/features/shared/recommendations/presentation/widgets/recommendation_card.dart';

/// Section widget for displaying recommendations
/// This widget handles loading, displaying, and error states for recommendations
class RecommendationSection extends StatelessWidget {
  final String currentItemId;
  final RecommendationType type;
  final RecommendationCriteriaEntity? criteria;
  final String title;
  final Function(String itemId, RecommendationType type) onItemTap;

  const RecommendationSection({
    super.key,
    required this.currentItemId,
    required this.type,
    this.criteria,
    this.title = 'Similar Items',
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<RecommendationCubit>()
        ..loadRecommendations(
          currentItemId: currentItemId,
          type: type,
          criteria: criteria,
        ),
      child: BlocBuilder<RecommendationCubit, RecommendationState>(
        builder: (context, state) {
          if (state is RecommendationsLoading) {
            return _buildLoadingState(context);
          }

          if (state is RecommendationError) {
            return const SizedBox.shrink(); // Hide on error
          }

          if (state is RecommendationsLoaded) {
            if (state.recommendations.isEmpty) {
              return const SizedBox.shrink(); // Hide if no recommendations
            }

            return _buildRecommendationsList(context, state.recommendations);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) => Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: const ShimmerLoading(
                  width: 160,
                  height: 200,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsList(
    BuildContext context,
    List<RecommendationEntity> recommendations,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final recommendation = recommendations[index];

                // For accommodation recommendations, fetch the accommodation data
                if (type == RecommendationType.accommodation) {
                  return _AccommodationRecommendationCard(
                    recommendation: recommendation,
                    onTap: () => onItemTap(recommendation.itemId, type),
                  );
                }

                // For other types, show placeholder (can be extended later)
                return RecommendationCard(
                  recommendation: recommendation,
                  imageUrl: '',
                  title: 'Loading...',
                  price: '',
                  onTap: () => onItemTap(recommendation.itemId, type),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget that fetches and displays accommodation data for a recommendation
class _AccommodationRecommendationCard extends StatelessWidget {
  final RecommendationEntity recommendation;
  final VoidCallback onTap;

  const _AccommodationRecommendationCard({
    required this.recommendation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AccommodationBloc>()
        ..add(
          LoadAccommodationByIdEvent(accommodationId: recommendation.itemId),
        ),
      child: BlocBuilder<AccommodationBloc, AccommodationState>(
        builder: (context, state) {
          if (state is AccommodationLoading) {
            return Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              child: const ShimmerLoading(
                width: 160,
                height: 200,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            );
          }

          if (state is AccommodationError || state is! AccommodationLoaded) {
            return const SizedBox.shrink();
          }

          final accommodation = state.accommodation;
          final imageUrl = accommodation.images.isNotEmpty
              ? accommodation.images.first
              : '';
          final priceText =
              'TZS ${accommodation.price.toStringAsFixed(0)}/${PriceTypes.getDisplayName(accommodation.priceType)}';

          return RecommendationCard(
            recommendation: recommendation,
            imageUrl: imageUrl,
            title: accommodation.name,
            price: priceText,
            subtitle: accommodation.location,
            onTap: onTap,
          );
        },
      ),
    );
  }
}
