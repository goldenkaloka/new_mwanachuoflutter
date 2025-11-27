import 'package:flutter/foundation.dart';
import 'package:mwanachuo/core/constants/database_constants.dart';
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

      final reviewModel = ReviewModel.fromJson({
        ...response,
        'user_name': response['users']['full_name'],
        'user_avatar': response['users']['avatar_url'],
      });

      // Send push notification to listing owner
      try {
        // Get listing owner ID based on item type
        String? ownerId;
        String itemTableName;
        String ownerIdColumn;

        switch (itemType) {
          case ReviewType.product:
            itemTableName = DatabaseConstants.productsTable;
            ownerIdColumn = 'seller_id';
            break;
          case ReviewType.service:
            itemTableName = DatabaseConstants.servicesTable;
            ownerIdColumn = 'provider_id';
            break;
          case ReviewType.accommodation:
            itemTableName = DatabaseConstants.accommodationsTable;
            ownerIdColumn = 'owner_id';
            break;
        }

        final itemResponse = await supabaseClient
            .from(itemTableName)
            .select('$ownerIdColumn, title')
            .eq('id', itemId)
            .single();

        ownerId = itemResponse[ownerIdColumn] as String?;
        final itemTitle = itemResponse['title'] as String?;

        if (ownerId != null && ownerId != currentUser.id) {
          final reviewerName = response['users']['full_name'] as String;
          final ratingStars = '⭐' * rating.toInt();
          final reviewMessage = comment != null && comment.isNotEmpty
              ? '$reviewerName left a $ratingStars review: "${comment.length > 50 ? '${comment.substring(0, 50)}...' : comment}"'
              : '$reviewerName left a $ratingStars review';

          // Determine action URL based on item type
          String actionUrl;
          switch (itemType) {
            case ReviewType.product:
              actionUrl = '/product-details?productId=$itemId';
              break;
            case ReviewType.service:
              actionUrl = '/service-details?serviceId=$itemId';
              break;
            case ReviewType.accommodation:
              actionUrl = '/accommodation-details?accommodationId=$itemId';
              break;
          }

          // Call push notification function
          await supabaseClient.rpc(
            'send_push_notification',
            params: {
              'p_user_id': ownerId,
              'p_title': 'New Review on ${itemTitle ?? 'Your Listing'}',
              'p_message': reviewMessage,
              'p_type': 'review',
              'p_action_url': actionUrl,
              'p_metadata': {
                'itemId': itemId,
                'itemType': _reviewTypeToString(itemType),
                'reviewerId': currentUser.id,
                'reviewerName': reviewerName,
                'rating': rating,
              },
            },
          );
        }
      } catch (e) {
        debugPrint('⚠️ Failed to send push notification for review: $e');
        // Don't throw - review was submitted successfully, just push notification failed
      }

      return reviewModel;
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

