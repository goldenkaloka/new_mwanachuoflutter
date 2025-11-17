import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/shared/reviews/data/models/review_model.dart';
import 'package:mwanachuo/features/shared/reviews/data/models/review_stats_model.dart';
import 'package:mwanachuo/features/shared/reviews/domain/entities/review_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract class defining review remote data source operations
abstract class ReviewRemoteDataSource {
  /// Get reviews for an item
  Future<List<ReviewModel>> getReviews({
    required String itemId,
    required ReviewType itemType,
    int? limit,
    int? offset,
  });

  /// Get review statistics
  Future<ReviewStatsModel> getReviewStats({
    required String itemId,
    required ReviewType itemType,
  });

  /// Submit a review
  Future<ReviewModel> submitReview({
    required String itemId,
    required ReviewType itemType,
    required double rating,
    String? comment,
    List<String>? imageUrls,
  });

  /// Update a review
  Future<ReviewModel> updateReview({
    required String reviewId,
    required double rating,
    String? comment,
    List<String>? imageUrls,
  });

  /// Delete a review
  Future<void> deleteReview(String reviewId);

  /// Mark a review as helpful
  Future<void> markReviewHelpful(String reviewId);

  /// Get user's review for an item
  Future<ReviewModel?> getUserReview({
    required String itemId,
    required ReviewType itemType,
  });
}

/// Implementation of ReviewRemoteDataSource using Supabase
class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  final SupabaseClient supabaseClient;

  ReviewRemoteDataSourceImpl({required this.supabaseClient});

  String _getTableName(ReviewType type) {
    switch (type) {
      case ReviewType.product:
        return 'product_reviews';
      case ReviewType.service:
        return 'service_reviews';
      case ReviewType.accommodation:
        return 'accommodation_reviews';
    }
  }

  @override
  Future<List<ReviewModel>> getReviews({
    required String itemId,
    required ReviewType itemType,
    int? limit,
    int? offset,
  }) async {
    try {
      final tableName = _getTableName(itemType);
      
      var query = supabaseClient
          .from(tableName)
          .select('*, users!inner(full_name, avatar_url)')
          .eq('item_id', itemId)
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 10) - 1);
      }

      final response = await query;

      return (response as List)
          .map((json) => ReviewModel.fromJson({
                ...json,
                'user_name': json['users']['full_name'],
                'user_avatar': json['users']['avatar_url'],
              }))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get reviews: $e');
    }
  }

  @override
  Future<ReviewStatsModel> getReviewStats({
    required String itemId,
    required ReviewType itemType,
  }) async {
    try {
      final tableName = _getTableName(itemType);
      
      final response = await supabaseClient
          .from(tableName)
          .select('rating')
          .eq('item_id', itemId);

      return ReviewStatsModel.fromReviews(
        itemId: itemId,
        reviews: (response as List).cast<Map<String, dynamic>>(),
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get review stats: $e');
    }
  }

  @override
  Future<ReviewModel> submitReview({
    required String itemId,
    required ReviewType itemType,
    required double rating,
    String? comment,
    List<String>? imageUrls,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      final tableName = _getTableName(itemType);

      final response = await supabaseClient
          .from(tableName)
          .insert({
            'user_id': currentUser.id,
            'item_id': itemId,
            'item_type': _reviewTypeToString(itemType),
            'rating': rating,
            'comment': comment,
            'images': imageUrls,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('*, users!inner(full_name, avatar_url)')
          .single();

      return ReviewModel.fromJson({
        ...response,
        'user_name': response['users']['full_name'],
        'user_avatar': response['users']['avatar_url'],
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to submit review: $e');
    }
  }

  @override
  Future<ReviewModel> updateReview({
    required String reviewId,
    required double rating,
    String? comment,
    List<String>? imageUrls,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      // Get the review's item type first
      final existingReview = await supabaseClient
          .from('product_reviews')
          .select('item_type')
          .eq('id', reviewId)
          .maybeSingle();

      if (existingReview == null) {
        throw ServerException('Review not found');
      }

      final itemType = _reviewTypeFromString(existingReview['item_type']);
      final tableName = _getTableName(itemType);

      final response = await supabaseClient
          .from(tableName)
          .update({
            'rating': rating,
            'comment': comment,
            'images': imageUrls,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reviewId)
          .eq('user_id', currentUser.id)
          .select('*, users!inner(full_name, avatar_url)')
          .single();

      return ReviewModel.fromJson({
        ...response,
        'user_name': response['users']['full_name'],
        'user_avatar': response['users']['avatar_url'],
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to update review: $e');
    }
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      // Try all tables to find and delete the review
      for (final type in ReviewType.values) {
        final tableName = _getTableName(type);
        try {
          await supabaseClient
              .from(tableName)
              .delete()
              .eq('id', reviewId)
              .eq('user_id', currentUser.id);
          return;
        } catch (_) {
          continue;
        }
      }

      throw ServerException('Review not found');
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to delete review: $e');
    }
  }

  @override
  Future<void> markReviewHelpful(String reviewId) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      // Try all tables to find and update the review
      for (final type in ReviewType.values) {
        final tableName = _getTableName(type);
        try {
          await supabaseClient.rpc('increment_helpful_count', params: {
            'review_id': reviewId,
            'table_name': tableName,
          });
          return;
        } catch (_) {
          continue;
        }
      }

      throw ServerException('Review not found');
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to mark review as helpful: $e');
    }
  }

  @override
  Future<ReviewModel?> getUserReview({
    required String itemId,
    required ReviewType itemType,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      final tableName = _getTableName(itemType);

      final response = await supabaseClient
          .from(tableName)
          .select('*, users!inner(full_name, avatar_url)')
          .eq('item_id', itemId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return ReviewModel.fromJson({
        ...response,
        'user_name': response['users']['full_name'],
        'user_avatar': response['users']['avatar_url'],
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get user review: $e');
    }
  }

  String _reviewTypeToString(ReviewType type) {
    switch (type) {
      case ReviewType.product:
        return 'product';
      case ReviewType.service:
        return 'service';
      case ReviewType.accommodation:
        return 'accommodation';
    }
  }

  ReviewType _reviewTypeFromString(String type) {
    switch (type) {
      case 'product':
        return ReviewType.product;
      case 'service':
        return ReviewType.service;
      case 'accommodation':
        return ReviewType.accommodation;
      default:
        throw ArgumentError('Invalid review type: $type');
    }
  }
}

