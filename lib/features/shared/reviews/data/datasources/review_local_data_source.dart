import 'dart:convert';
import 'package:mwanachuo/core/constants/storage_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/shared/reviews/data/models/review_model.dart';
import 'package:mwanachuo/features/shared/reviews/data/models/review_stats_model.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract class defining review local data source operations
abstract class ReviewLocalDataSource {
  /// Cache reviews
  Future<void> cacheReviews({
    required String itemId,
    required ReviewType itemType,
    required List<ReviewModel> reviews,
  });

  /// Get cached reviews
  Future<List<ReviewModel>> getCachedReviews({
    required String itemId,
    required ReviewType itemType,
  });

  /// Cache review stats
  Future<void> cacheReviewStats({
    required String itemId,
    required ReviewType itemType,
    required ReviewStatsModel stats,
  });

  /// Get cached review stats
  Future<ReviewStatsModel> getCachedReviewStats({
    required String itemId,
    required ReviewType itemType,
  });

  /// Clear cache for an item
  Future<void> clearCache({
    required String itemId,
    required ReviewType itemType,
  });
}

/// Implementation of ReviewLocalDataSource using SharedPreferences
class ReviewLocalDataSourceImpl implements ReviewLocalDataSource {
  final SharedPreferences sharedPreferences;

  ReviewLocalDataSourceImpl({required this.sharedPreferences});

  String _getReviewsCacheKey(String itemId, ReviewType itemType) {
    return '${StorageConstants.reviewsCachePrefix}_${_typeToString(itemType)}_$itemId';
  }

  String _getStatsCacheKey(String itemId, ReviewType itemType) {
    return '${StorageConstants.reviewStatsCachePrefix}_${_typeToString(itemType)}_$itemId';
  }

  String _typeToString(ReviewType type) {
    switch (type) {
      case ReviewType.product:
        return 'product';
      case ReviewType.service:
        return 'service';
      case ReviewType.accommodation:
        return 'accommodation';
    }
  }

  @override
  Future<void> cacheReviews({
    required String itemId,
    required ReviewType itemType,
    required List<ReviewModel> reviews,
  }) async {
    try {
      final key = _getReviewsCacheKey(itemId, itemType);
      final jsonList = reviews.map((review) => review.toJson()).toList();
      await sharedPreferences.setString(key, json.encode(jsonList));
    } catch (e) {
      throw CacheException('Failed to cache reviews: $e');
    }
  }

  @override
  Future<List<ReviewModel>> getCachedReviews({
    required String itemId,
    required ReviewType itemType,
  }) async {
    try {
      final key = _getReviewsCacheKey(itemId, itemType);
      final jsonString = sharedPreferences.getString(key);

      if (jsonString == null) {
        throw CacheException('No cached reviews found');
      }

      final jsonList = json.decode(jsonString) as List;
      return jsonList
          .map((json) => ReviewModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw CacheException('Failed to get cached reviews: $e');
    }
  }

  @override
  Future<void> cacheReviewStats({
    required String itemId,
    required ReviewType itemType,
    required ReviewStatsModel stats,
  }) async {
    try {
      final key = _getStatsCacheKey(itemId, itemType);
      await sharedPreferences.setString(key, json.encode(stats.toJson()));
    } catch (e) {
      throw CacheException('Failed to cache review stats: $e');
    }
  }

  @override
  Future<ReviewStatsModel> getCachedReviewStats({
    required String itemId,
    required ReviewType itemType,
  }) async {
    try {
      final key = _getStatsCacheKey(itemId, itemType);
      final jsonString = sharedPreferences.getString(key);

      if (jsonString == null) {
        throw CacheException('No cached review stats found');
      }

      return ReviewStatsModel.fromJson(
        json.decode(jsonString) as Map<String, dynamic>,
      );
    } catch (e) {
      throw CacheException('Failed to get cached review stats: $e');
    }
  }

  @override
  Future<void> clearCache({
    required String itemId,
    required ReviewType itemType,
  }) async {
    try {
      final reviewsKey = _getReviewsCacheKey(itemId, itemType);
      final statsKey = _getStatsCacheKey(itemId, itemType);

      await Future.wait([
        sharedPreferences.remove(reviewsKey),
        sharedPreferences.remove(statsKey),
      ]);
    } catch (e) {
      throw CacheException('Failed to clear cache: $e');
    }
  }
}

