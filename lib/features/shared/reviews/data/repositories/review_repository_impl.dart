import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/network/network_info.dart';
import 'package:mwanachuo/features/shared/reviews/data/datasources/review_local_data_source.dart';
import 'package:mwanachuo/features/shared/reviews/data/datasources/review_remote_data_source.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_entity.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_stats_entity.dart';
import 'package:mwanachuo/features/shared/reviews/domain/repositories/review_repository.dart';

/// Implementation of ReviewRepository
class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource remoteDataSource;
  final ReviewLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ReviewRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ReviewEntity>>> getReviews({
    required String itemId,
    required ReviewType itemType,
    int? limit,
    int? offset,
  }) async {
    if (!await networkInfo.isConnected) {
      // Try to get from cache
      try {
        final cachedReviews = await localDataSource.getCachedReviews(
          itemId: itemId,
          itemType: itemType,
        );
        return Right(cachedReviews);
      } on CacheException {
        return Left(NetworkFailure('No internet connection and no cached data'));
      }
    }

    try {
      final reviews = await remoteDataSource.getReviews(
        itemId: itemId,
        itemType: itemType,
        limit: limit,
        offset: offset,
      );

      // Cache reviews
      await localDataSource.cacheReviews(
        itemId: itemId,
        itemType: itemType,
        reviews: reviews,
      );

      return Right(reviews);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get reviews: $e'));
    }
  }

  @override
  Future<Either<Failure, ReviewStatsEntity>> getReviewStats({
    required String itemId,
    required ReviewType itemType,
  }) async {
    if (!await networkInfo.isConnected) {
      // Try to get from cache
      try {
        final cachedStats = await localDataSource.getCachedReviewStats(
          itemId: itemId,
          itemType: itemType,
        );
        return Right(cachedStats);
      } on CacheException {
        return Left(NetworkFailure('No internet connection and no cached data'));
      }
    }

    try {
      final stats = await remoteDataSource.getReviewStats(
        itemId: itemId,
        itemType: itemType,
      );

      // Cache stats
      await localDataSource.cacheReviewStats(
        itemId: itemId,
        itemType: itemType,
        stats: stats,
      );

      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get review stats: $e'));
    }
  }

  @override
  Future<Either<Failure, ReviewEntity>> submitReview({
    required String itemId,
    required ReviewType itemType,
    required double rating,
    String? comment,
    List<String>? imageUrls,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final review = await remoteDataSource.submitReview(
        itemId: itemId,
        itemType: itemType,
        rating: rating,
        comment: comment,
        imageUrls: imageUrls,
      );

      // Clear cache to force refresh
      await localDataSource.clearCache(
        itemId: itemId,
        itemType: itemType,
      );

      return Right(review);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to submit review: $e'));
    }
  }

  @override
  Future<Either<Failure, ReviewEntity>> updateReview({
    required String reviewId,
    required double rating,
    String? comment,
    List<String>? imageUrls,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final review = await remoteDataSource.updateReview(
        reviewId: reviewId,
        rating: rating,
        comment: comment,
        imageUrls: imageUrls,
      );

      // Clear cache to force refresh
      await localDataSource.clearCache(
        itemId: review.itemId,
        itemType: review.itemType,
      );

      return Right(review);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to update review: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReview(String reviewId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.deleteReview(reviewId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to delete review: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markReviewHelpful(String reviewId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.markReviewHelpful(reviewId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to mark review as helpful: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasUserReviewed({
    required String itemId,
    required ReviewType itemType,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final review = await remoteDataSource.getUserReview(
        itemId: itemId,
        itemType: itemType,
      );
      return Right(review != null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to check user review: $e'));
    }
  }

  @override
  Future<Either<Failure, ReviewEntity?>> getUserReview({
    required String itemId,
    required ReviewType itemType,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final review = await remoteDataSource.getUserReview(
        itemId: itemId,
        itemType: itemType,
      );
      return Right(review);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get user review: $e'));
    }
  }
}

