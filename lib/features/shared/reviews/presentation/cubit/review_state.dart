import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_entity.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_stats_entity.dart';

/// Base class for all review states
abstract class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ReviewInitial extends ReviewState {}

/// Loading reviews
class ReviewsLoading extends ReviewState {}

/// Reviews loaded successfully
class ReviewsLoaded extends ReviewState {
  final List<ReviewEntity> reviews;
  final ReviewStatsEntity? stats;

  const ReviewsLoaded({
    required this.reviews,
    this.stats,
  });

  @override
  List<Object?> get props => [reviews, stats];
}

/// Loading review stats
class ReviewStatsLoading extends ReviewState {}

/// Review stats loaded successfully
class ReviewStatsLoaded extends ReviewState {
  final ReviewStatsEntity stats;

  const ReviewStatsLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

/// Submitting a review
class ReviewSubmitting extends ReviewState {}

/// Review submitted successfully
class ReviewSubmitted extends ReviewState {
  final ReviewEntity review;

  const ReviewSubmitted({required this.review});

  @override
  List<Object?> get props => [review];
}

/// Updating a review
class ReviewUpdating extends ReviewState {}

/// Review updated successfully
class ReviewUpdated extends ReviewState {
  final ReviewEntity review;

  const ReviewUpdated({required this.review});

  @override
  List<Object?> get props => [review];
}

/// Deleting a review
class ReviewDeleting extends ReviewState {}

/// Review deleted successfully
class ReviewDeleted extends ReviewState {}

/// Marking review as helpful
class ReviewMarkingHelpful extends ReviewState {}

/// Review marked as helpful
class ReviewMarkedHelpful extends ReviewState {}

/// Loading user's review
class UserReviewLoading extends ReviewState {}

/// User's review loaded
class UserReviewLoaded extends ReviewState {
  final ReviewEntity? review;
  final bool hasReviewed;

  const UserReviewLoaded({
    this.review,
    required this.hasReviewed,
  });

  @override
  List<Object?> get props => [review, hasReviewed];
}

/// Error state
class ReviewError extends ReviewState {
  final String message;

  const ReviewError({required this.message});

  @override
  List<Object?> get props => [message];
}

