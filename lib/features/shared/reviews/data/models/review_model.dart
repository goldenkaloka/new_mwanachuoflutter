import 'package:mwanachuo/features/shared/reviews/domain/entities/review_entity.dart';

/// Review model for the data layer
class ReviewModel extends ReviewEntity {
  const ReviewModel({
    required super.id,
    required super.userId,
    required super.userName,
    super.userAvatar,
    required super.itemId,
    required super.itemType,
    required super.rating,
    super.comment,
    super.images,
    super.helpfulCount,
    super.isVerifiedPurchase,
    required super.createdAt,
    super.updatedAt,
  });

  /// Create a ReviewModel from JSON
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userAvatar: json['user_avatar'] as String?,
      itemId: json['item_id'] as String,
      itemType: _reviewTypeFromString(json['item_type'] as String),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String?,
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : null,
      helpfulCount: json['helpful_count'] as int? ?? 0,
      isVerifiedPurchase: json['is_verified_purchase'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert ReviewModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'item_id': itemId,
      'item_type': _reviewTypeToString(itemType),
      'rating': rating,
      'comment': comment,
      'images': images,
      'helpful_count': helpfulCount,
      'is_verified_purchase': isVerifiedPurchase,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static ReviewType _reviewTypeFromString(String type) {
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

  static String _reviewTypeToString(ReviewType type) {
    switch (type) {
      case ReviewType.product:
        return 'product';
      case ReviewType.service:
        return 'service';
      case ReviewType.accommodation:
        return 'accommodation';
    }
  }
}
