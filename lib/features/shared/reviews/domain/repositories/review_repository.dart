import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_entity.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_stats_entity.dart';

/// Review repository interface
abstract class ReviewRepository {
  /// Get reviews for an item (product, service, or accommodation)
  Future<Either<Failure, List<ReviewEntity>>> getReviews({
    required String itemId,
    required ReviewType itemType,
    int? limit,
    int? offset,
  });

  /// Get review statistics for an item
  Future<Either<Failure, ReviewStatsEntity>> getReviewStats({
    required String itemId,
    required ReviewType itemType,
  });

  /// Submit a review
  Future<Either<Failure, ReviewEntity>> submitReview({
    required String itemId,
    required ReviewType itemType,
    required double rating,
    String? comment,
    List<String>? imageUrls,
  });

  /// Update a review
  Future<Either<Failure, ReviewEntity>> updateReview({
    required String reviewId,
    required double rating,
    String? comment,
    List<String>? imageUrls,
  });

  /// Delete a review
  Future<Either<Failure, void>> deleteReview(String reviewId);

  /// Mark a review as helpful
  Future<Either<Failure, void>> markReviewHelpful(String reviewId);

  /// Check if user has reviewed an item
  Future<Either<Failure, bool>> hasUserReviewed({
    required String itemId,
    required ReviewType itemType,
  });

  /// Get user's review for an item
  Future<Either<Failure, ReviewEntity?>> getUserReview({
    required String itemId,
    required ReviewType itemType,
  });
}

