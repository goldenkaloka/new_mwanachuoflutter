import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_entity.dart';
import 'package:mwanachuo/features/shared/reviews/domain/usecases/delete_review.dart';
import 'package:mwanachuo/features/shared/reviews/domain/usecases/get_review_stats.dart';
import 'package:mwanachuo/features/shared/reviews/domain/usecases/get_reviews.dart';
import 'package:mwanachuo/features/shared/reviews/domain/usecases/get_user_review.dart';
import 'package:mwanachuo/features/shared/reviews/domain/usecases/mark_review_helpful.dart';
import 'package:mwanachuo/features/shared/reviews/domain/usecases/submit_review.dart';
import 'package:mwanachuo/features/shared/reviews/domain/usecases/update_review.dart';
import 'package:mwanachuo/features/shared/reviews/presentation/cubit/review_state.dart';

/// Cubit for managing review state
class ReviewCubit extends Cubit<ReviewState> {
  final GetReviews getReviews;
  final GetReviewStats getReviewStats;
  final SubmitReview submitReview;
  final UpdateReview updateReview;
  final DeleteReview deleteReview;
  final MarkReviewHelpful markReviewHelpful;
  final GetUserReview getUserReview;

  ReviewCubit({
    required this.getReviews,
    required this.getReviewStats,
    required this.submitReview,
    required this.updateReview,
    required this.deleteReview,
    required this.markReviewHelpful,
    required this.getUserReview,
  }) : super(ReviewInitial());

  /// Load reviews for an item
  Future<void> loadReviews({
    required String itemId,
    required ReviewType itemType,
    int? limit,
    int? offset,
  }) async {
    emit(ReviewsLoading());

    final result = await getReviews(
      GetReviewsParams(
        itemId: itemId,
        itemType: itemType,
        limit: limit,
        offset: offset,
      ),
    );

    result.fold(
      (failure) => emit(ReviewError(message: failure.message)),
      (reviews) => emit(ReviewsLoaded(reviews: reviews)),
    );
  }

  /// Load reviews with stats
  Future<void> loadReviewsWithStats({
    required String itemId,
    required ReviewType itemType,
    int? limit,
    int? offset,
  }) async {
    emit(ReviewsLoading());

    // Load both reviews and stats
    final reviewsResult = await getReviews(
      GetReviewsParams(
        itemId: itemId,
        itemType: itemType,
        limit: limit,
        offset: offset,
      ),
    );

    final statsResult = await getReviewStats(
      GetReviewStatsParams(
        itemId: itemId,
        itemType: itemType,
      ),
    );

    reviewsResult.fold(
      (failure) => emit(ReviewError(message: failure.message)),
      (reviews) {
        statsResult.fold(
          (failure) => emit(ReviewsLoaded(reviews: reviews)),
          (stats) => emit(ReviewsLoaded(reviews: reviews, stats: stats)),
        );
      },
    );
  }

  /// Load review stats only
  Future<void> loadStats({
    required String itemId,
    required ReviewType itemType,
  }) async {
    emit(ReviewStatsLoading());

    final result = await getReviewStats(
      GetReviewStatsParams(
        itemId: itemId,
        itemType: itemType,
      ),
    );

    result.fold(
      (failure) => emit(ReviewError(message: failure.message)),
      (stats) => emit(ReviewStatsLoaded(stats: stats)),
    );
  }

  /// Submit a new review
  Future<void> submitNewReview({
    required String itemId,
    required ReviewType itemType,
    required double rating,
    String? comment,
    List<String>? imageUrls,
  }) async {
    emit(ReviewSubmitting());

    final result = await submitReview(
      SubmitReviewParams(
        itemId: itemId,
        itemType: itemType,
        rating: rating,
        comment: comment,
        imageUrls: imageUrls,
      ),
    );

    result.fold(
      (failure) => emit(ReviewError(message: failure.message)),
      (review) => emit(ReviewSubmitted(review: review)),
    );
  }

  /// Update an existing review
  Future<void> updateExistingReview({
    required String reviewId,
    required double rating,
    String? comment,
    List<String>? imageUrls,
  }) async {
    emit(ReviewUpdating());

    final result = await updateReview(
      UpdateReviewParams(
        reviewId: reviewId,
        rating: rating,
        comment: comment,
        imageUrls: imageUrls,
      ),
    );

    result.fold(
      (failure) => emit(ReviewError(message: failure.message)),
      (review) => emit(ReviewUpdated(review: review)),
    );
  }

  /// Delete a review
  Future<void> deleteExistingReview(String reviewId) async {
    emit(ReviewDeleting());

    final result = await deleteReview(DeleteReviewParams(reviewId: reviewId));

    result.fold(
      (failure) => emit(ReviewError(message: failure.message)),
      (_) => emit(ReviewDeleted()),
    );
  }

  /// Mark a review as helpful
  Future<void> markAsHelpful(String reviewId) async {
    emit(ReviewMarkingHelpful());

    final result = await markReviewHelpful(
      MarkReviewHelpfulParams(reviewId: reviewId),
    );

    result.fold(
      (failure) => emit(ReviewError(message: failure.message)),
      (_) => emit(ReviewMarkedHelpful()),
    );
  }

  /// Load user's review for an item
  Future<void> loadUserReview({
    required String itemId,
    required ReviewType itemType,
  }) async {
    emit(UserReviewLoading());

    final result = await getUserReview(
      GetUserReviewParams(
        itemId: itemId,
        itemType: itemType,
      ),
    );

    result.fold(
      (failure) => emit(ReviewError(message: failure.message)),
      (review) => emit(UserReviewLoaded(
        review: review,
        hasReviewed: review != null,
      )),
    );
  }

  /// Reset to initial state
  void reset() {
    emit(ReviewInitial());
  }
}

