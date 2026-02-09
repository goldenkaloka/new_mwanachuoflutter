import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mwanachuo/core/constants/app_constants.dart';
import 'package:mwanachuo/core/utils/responsive.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_entity.dart';
import 'package:mwanachuo/features/shared/reviews/presentation/cubit/review_cubit.dart';
import 'package:mwanachuo/features/shared/reviews/presentation/cubit/review_state.dart';

class CommentsAndRatingsSection extends StatefulWidget {
  final String itemId;
  final String itemType; // 'product', 'service', 'accommodation', 'promotion'

  const CommentsAndRatingsSection({
    super.key,
    required this.itemId,
    required this.itemType,
  });

  @override
  State<CommentsAndRatingsSection> createState() =>
      _CommentsAndRatingsSectionState();
}

class _CommentsAndRatingsSectionState extends State<CommentsAndRatingsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewCubit>().loadReviewsWithStats(
        itemId: widget.itemId,
        itemType: _getReviewType(),
        limit: 10,
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  ReviewType _getReviewType() {
    switch (widget.itemType) {
      case 'product':
        return ReviewType.product;
      case 'service':
        return ReviewType.service;
      case 'accommodation':
        return ReviewType.accommodation;
      default:
        return ReviewType.product;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final primaryTextColor = kTextPrimary;
    final secondaryTextColor = Colors.grey[600]!;

    return BlocConsumer<ReviewCubit, ReviewState>(
      listener: (context, state) {
        if (state is ReviewSubmitted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review submitted successfully!')),
          );
          // Reload reviews after submission
          context.read<ReviewCubit>().loadReviewsWithStats(
            itemId: widget.itemId,
            itemType: _getReviewType(),
            limit: 10,
          );
        } else if (state is ReviewError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
        } else if (state is ReviewMarkedHelpful) {
          // Reload reviews after marking as helpful
          context.read<ReviewCubit>().loadReviewsWithStats(
            itemId: widget.itemId,
            itemType: _getReviewType(),
            limit: 10,
          );
        }
      },
      builder: (context, state) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return ResponsiveBuilder(
          builder: (context, screenSize) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ratings Overview
                _buildRatingsOverview(context, state, screenSize, isDarkMode),

                const SizedBox(height: 24),

                // Filter Chips
                _buildFilterChips(context, isDarkMode),

                const SizedBox(height: 16),

                // Reviews List
                _buildReviewsList(
                  context,
                  state,
                  primaryTextColor,
                  secondaryTextColor,
                  screenSize,
                  isDarkMode,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChips(BuildContext context, bool isDarkMode) {
    final chips = ['All', 'With Photos', '5 Stars', 'Verified'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? kPrimaryColor
                  : kPrimaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? kPrimaryColor
                    : kPrimaryColor.withValues(alpha: 0.2),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              chips[index],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDarkMode ? Colors.white : const Color(0xFF11221F)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingsOverview(
    BuildContext context,
    ReviewState state,
    ScreenSize screenSize,
    bool isDarkMode,
  ) {
    if (state is ReviewsLoading || state is ReviewInitial) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(color: kPrimaryColor),
        ),
      );
    }

    // Extract stats and reviews from state
    final stats = state is ReviewsLoaded ? state.stats : null;
    final reviews = state is ReviewsLoaded ? state.reviews : <ReviewEntity>[];

    double averageRating = stats?.averageRating ?? 0.0;
    int totalReviews = stats?.totalReviews ?? 0;
    Map<int, int> ratingDistribution =
        stats?.ratingDistribution ?? {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    // If stats are missing or showing 0 but we have reviews, calculate locally for better UX
    if (totalReviews == 0 && reviews.isNotEmpty) {
      totalReviews = reviews.length;
      double sum = 0;
      final dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      for (final r in reviews) {
        final rInt = r.rating.toInt();
        sum += r.rating;
        if (dist.containsKey(rInt)) {
          dist[rInt] = dist[rInt]! + 1;
        }
      }
      averageRating = sum / totalReviews;
      ratingDistribution = dist;
    }

    final effectiveTotalReviews = totalReviews;

    if (effectiveTotalReviews == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDarkMode ? kSurfaceColorDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: kPrimaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: GoogleFonts.plusJakartaSans(
                color: isDarkMode ? Colors.white : const Color(0xFF11221F),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share your experience!',
              style: GoogleFonts.plusJakartaSans(
                color: (isDarkMode ? Colors.white : const Color(0xFF11221F))
                    .withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? kSurfaceColorDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Average Rating
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: GoogleFonts.plusJakartaSans(
                    color: isDarkMode ? Colors.white : const Color(0xFF11221F),
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    if (averageRating >= starValue) {
                      return const Icon(
                        Icons.star,
                        color: kPrimaryColor,
                        size: 20,
                      );
                    } else if (averageRating >= starValue - 0.5) {
                      return const Icon(
                        Icons.star_half,
                        color: kPrimaryColor,
                        size: 20,
                      );
                    } else {
                      return const Icon(
                        Icons.star_border,
                        color: kPrimaryColor,
                        size: 20,
                      );
                    }
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  '$effectiveTotalReviews verified reviews',
                  style: GoogleFonts.plusJakartaSans(
                    color: (isDarkMode ? Colors.white : const Color(0xFF11221F))
                        .withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Rating Distribution
          Expanded(
            flex: 3,
            child: Column(
              children: [5, 4, 3, 2, 1].map((rating) {
                final count = ratingDistribution[rating] ?? 0;
                final percentage = effectiveTotalReviews == 0
                    ? 0.0
                    : count / effectiveTotalReviews;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Text(
                        '$rating',
                        style: GoogleFonts.plusJakartaSans(
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF11221F),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: percentage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${(percentage * 100).toInt()}%',
                          style: GoogleFonts.plusJakartaSans(
                            color:
                                (isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF11221F))
                                    .withValues(alpha: 0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList(
    BuildContext context,
    ReviewState state,
    Color primaryTextColor,
    Color secondaryTextColor,
    ScreenSize screenSize,
    bool isDarkMode,
  ) {
    // Extract reviews from state
    final reviews = state is ReviewsLoaded ? state.reviews : <ReviewEntity>[];
    final hasMore = state is ReviewsLoaded ? state.hasMore : false;
    final isLoadingMore = state is ReviewsLoaded ? state.isLoadingMore : false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Reviews',
          style: GoogleFonts.plusJakartaSans(
            color: primaryTextColor,
            fontSize: ResponsiveBreakpoints.responsiveValue(
              context,
              compact: 18.0,
              medium: 20.0,
              expanded: 22.0,
            ),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16.0),

        if (state is ReviewsLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(32.0),
            alignment: Alignment.center,
            child: Text(
              'No reviews yet. Be the first to review!',
              style: GoogleFonts.plusJakartaSans(
                color: secondaryTextColor,
                fontSize: 16.0,
              ),
            ),
          )
        else ...[
          ...reviews.map((review) {
            return _buildReviewItem(context, review, screenSize, isDarkMode);
          }),

          // Load More Button
          if (hasMore) ...[
            const SizedBox(height: 16.0),
            Center(
              child: isLoadingMore
                  ? const CircularProgressIndicator()
                  : OutlinedButton(
                      onPressed: () {
                        context.read<ReviewCubit>().loadMoreReviews(
                          itemId: widget.itemId,
                          itemType: _getReviewType(),
                          offset: reviews.length,
                          limit: 10,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimaryColor,
                        side: const BorderSide(color: kPrimaryColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Load More Reviews',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildReviewItem(
    BuildContext context,
    ReviewEntity review,
    ScreenSize screenSize,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? kSurfaceColorDark : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // User Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimaryColor.withValues(alpha: 0.2),
                ),
                clipBehavior: Clip.antiAlias,
                child:
                    review.userAvatar != null && review.userAvatar!.isNotEmpty
                    ? Image.network(review.userAvatar!, fit: BoxFit.cover)
                    : Icon(Icons.person, color: kPrimaryColor),
              ),
              const SizedBox(width: 12.0),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.userName,
                          style: GoogleFonts.plusJakartaSans(
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF11221F),
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (review.isVerifiedPurchase) ...[
                          const SizedBox(width: 4.0),
                          Icon(Icons.verified, size: 14, color: kPrimaryColor),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      _formatDate(review.createdAt),
                      style: GoogleFonts.plusJakartaSans(
                        color:
                            (isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF11221F))
                                .withValues(alpha: 0.5),
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ),

              // Stars
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating.floor()
                        ? Icons.star
                        : Icons.star_border,
                    color: kPrimaryColor,
                    size: 16,
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 16.0),

          // Review Comment
          if (review.comment != null && review.comment!.isNotEmpty)
            Text(
              review.comment!,
              style: GoogleFonts.plusJakartaSans(
                color: isDarkMode ? Colors.white : const Color(0xFF11221F),
                fontSize: 14.0,
                height: 1.6,
              ),
            ),

          const SizedBox(height: 16.0),

          // Bottom Bar
          Divider(color: kPrimaryColor.withValues(alpha: 0.05)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  context.read<ReviewCubit>().markAsHelpful(review.id);
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.thumb_up_outlined,
                      size: 20.0,
                      color:
                          (isDarkMode ? Colors.white : const Color(0xFF11221F))
                              .withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Helpful${review.helpfulCount > 0 ? ' (${review.helpfulCount})' : ''}',
                      style: GoogleFonts.plusJakartaSans(
                        color:
                            (isDarkMode
                                    ? Colors.white
                                    : const Color(0xFF11221F))
                                .withValues(alpha: 0.5),
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Report',
                style: GoogleFonts.plusJakartaSans(
                  color: (isDarkMode ? Colors.white : const Color(0xFF11221F))
                      .withValues(alpha: 0.5),
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
