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
  final _commentController = TextEditingController();
  double _userRating = 0;

  @override
  void dispose() {
    _commentController.dispose();
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
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryTextColor = kTextPrimary;
    final secondaryTextColor = Colors.grey[600]!;
    final borderColor = Colors.grey[200]!;

    return BlocConsumer<ReviewCubit, ReviewState>(
      listener: (context, state) {
        if (state is ReviewSubmitted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review submitted successfully!')),
          );
          setState(() {
            _commentController.clear();
            _userRating = 0;
          });
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
        return ResponsiveBuilder(
          builder: (context, screenSize) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ratings Overview
                _buildRatingsOverview(
                  context,
                  state,
                  primaryTextColor,
                  secondaryTextColor,
                  borderColor,
                  screenSize,
                ),

                SizedBox(
                  height: ResponsiveBreakpoints.responsiveValue(
                    context,
                    compact: 24.0,
                    medium: 28.0,
                    expanded: 32.0,
                  ),
                ),

                // Add Review Section
                _buildAddReviewSection(
                  context,
                  state,
                  primaryTextColor,
                  secondaryTextColor,
                  borderColor,
                  screenSize,
                ),

                SizedBox(
                  height: ResponsiveBreakpoints.responsiveValue(
                    context,
                    compact: 24.0,
                    medium: 28.0,
                    expanded: 32.0,
                  ),
                ),

                // Reviews List
                _buildReviewsList(
                  context,
                  state,
                  primaryTextColor,
                  secondaryTextColor,
                  borderColor,
                  screenSize,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRatingsOverview(
    BuildContext context,
    ReviewState state,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color borderColor,
    ScreenSize screenSize,
  ) {
    // Extract stats from state
    final stats = state is ReviewsLoaded ? state.stats : null;
    final averageRating = stats?.averageRating ?? 0.0;
    final totalReviews = stats?.totalReviews ?? 0;
    final ratingDistribution =
        stats?.ratingDistribution ?? {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    return Container(
      padding: EdgeInsets.all(
        ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 20.0,
          medium: 24.0,
          expanded: 28.0,
        ),
      ),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Average Rating
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: GoogleFonts.inter(
                    color: primaryTextColor,
                    fontSize: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 48.0,
                      medium: 56.0,
                      expanded: 64.0,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStarRating(averageRating, 24.0),
                const SizedBox(height: 8.0),
                Text(
                  '$totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}',
                  style: GoogleFonts.inter(
                    color: secondaryTextColor,
                    fontSize: ResponsiveBreakpoints.responsiveValue(
                      context,
                      compact: 14.0,
                      medium: 15.0,
                      expanded: 16.0,
                    ),
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
                final percentage = totalReviews == 0
                    ? 0.0
                    : count / totalReviews;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Text(
                        '$rating',
                        style: GoogleFonts.inter(
                          color: secondaryTextColor,
                          fontSize: 14.0,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      Icon(Icons.star, size: 14.0, color: Colors.amber[600]),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: borderColor,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.amber[600]!,
                            ),
                            minHeight: 6.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        '$count',
                        style: GoogleFonts.inter(
                          color: secondaryTextColor,
                          fontSize: 14.0,
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

  Widget _buildAddReviewSection(
    BuildContext context,
    ReviewState state,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color borderColor,
    ScreenSize screenSize,
  ) {
    final isSubmitting = state is ReviewSubmitting;

    return Container(
      padding: EdgeInsets.all(
        ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 20.0,
          medium: 24.0,
          expanded: 28.0,
        ),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Write a Review',
            style: GoogleFonts.inter(
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

          // Star Rating Selector
          Row(
            children: [
              Text(
                'Your Rating:',
                style: GoogleFonts.inter(
                  color: secondaryTextColor,
                  fontSize: 14.0,
                ),
              ),
              const SizedBox(width: 12.0),
              ...List.generate(5, (index) {
                return GestureDetector(
                  onTap: isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _userRating = index + 1.0;
                          });
                        },
                  child: Icon(
                    index < _userRating ? Icons.star : Icons.star_border,
                    color: Colors.amber[600],
                    size: 32.0,
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 16.0),

          // Comment TextField
          TextField(
            controller: _commentController,
            maxLines: 4,
            enabled: !isSubmitting,
            decoration: InputDecoration(
              hintText: 'Share your experience...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: borderColor),
              ),
            ),
          ),

          const SizedBox(height: 16.0),

          // Submit Button (Secondary style - outlined)
          SizedBox(
            width: double.infinity,
            height: 44.0,
            child: OutlinedButton(
              onPressed: isSubmitting
                  ? null
                  : () {
                      if (_userRating > 0 &&
                          _commentController.text.trim().isNotEmpty) {
                        // Submit review using ReviewCubit
                        context.read<ReviewCubit>().submitNewReview(
                          itemId: widget.itemId,
                          itemType: _getReviewType(),
                          rating: _userRating,
                          comment: _commentController.text.trim(),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please provide a rating and comment',
                            ),
                          ),
                        );
                      }
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimaryColor,
                side: BorderSide(
                  color: kPrimaryColor,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
              child: isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                      ),
                    )
                  : Text(
                      'Submit Review',
                      style: GoogleFonts.inter(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
    Color borderColor,
    ScreenSize screenSize,
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
          style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
                color: secondaryTextColor,
                fontSize: 16.0,
              ),
            ),
          )
        else ...[
          ...reviews.map((review) {
            return _buildReviewItem(
              context,
              review,
              primaryTextColor,
              secondaryTextColor,
              borderColor,
              screenSize,
            );
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
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
    Color primaryTextColor,
    Color secondaryTextColor,
    Color borderColor,
    ScreenSize screenSize,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: EdgeInsets.all(
        ResponsiveBreakpoints.responsiveValue(
          context,
          compact: 16.0,
          medium: 20.0,
          expanded: 24.0,
        ),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // User Avatar
              CircleAvatar(
                radius: 20.0,
                backgroundColor: kPrimaryColor.withValues(alpha: 0.3),
                backgroundImage:
                    review.userAvatar != null && review.userAvatar!.isNotEmpty
                    ? NetworkImage(review.userAvatar!)
                    : null,
                child: review.userAvatar == null || review.userAvatar!.isEmpty
                    ? Text(
                        review.userName.isNotEmpty
                            ? review.userName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
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
                          style: GoogleFonts.inter(
                            color: primaryTextColor,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (review.isVerifiedPurchase) ...[
                          const SizedBox(width: 8.0),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              'Verified',
                              style: GoogleFonts.inter(
                                color: kPrimaryColor,
                                fontSize: 10.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2.0),
                    Row(
                      children: [
                        Flexible(
                          child: _buildStarRating(review.rating, 14.0),
                        ),
                        const SizedBox(width: 8.0),
                        Flexible(
                          child: Text(
                            _formatDate(review.createdAt),
                            style: GoogleFonts.inter(
                              color: secondaryTextColor,
                              fontSize: 13.0,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12.0),

          // Review Comment
          if (review.comment != null && review.comment!.isNotEmpty)
            Text(
              review.comment!,
              style: GoogleFonts.inter(
                color: primaryTextColor,
                fontSize: 14.0,
                height: 1.5,
              ),
            ),

          const SizedBox(height: 12.0),

          // Helpful Button
          TextButton.icon(
            onPressed: () {
              context.read<ReviewCubit>().markAsHelpful(review.id);
            },
            icon: Icon(
              Icons.thumb_up_outlined,
              size: 16.0,
              color: secondaryTextColor,
            ),
            label: Text(
              'Helpful${review.helpfulCount > 0 ? ' (${review.helpfulCount})' : ''}',
              style: GoogleFonts.inter(
                color: secondaryTextColor,
                fontSize: 13.0,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating, double size) {
    // Make icon size adaptive based on screen size
    final adaptiveSize = ResponsiveBreakpoints.responsiveValue(
      context,
      compact: size * 0.85,
      medium: size,
      expanded: size,
    );
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        Widget icon;
        if (index < rating.floor()) {
          icon = Icon(Icons.star, size: adaptiveSize, color: Colors.amber[600]);
        } else if (index < rating) {
          icon = Icon(Icons.star_half, size: adaptiveSize, color: Colors.amber[600]);
        } else {
          icon = Icon(Icons.star_border, size: adaptiveSize, color: Colors.amber[600]);
        }
        return Padding(
          padding: EdgeInsets.only(right: index < 4 ? 2.0 : 0),
          child: icon,
        );
      }),
    );
  }
}
