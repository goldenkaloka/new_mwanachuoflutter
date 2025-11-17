import 'package:equatable/equatable.dart';

/// Enum for review types
enum ReviewType {
  product,
  service,
  accommodation,
}

/// Review entity representing a user review
class ReviewEntity extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String itemId;
  final ReviewType itemType;
  final double rating;
  final String? comment;
  final List<String>? images;
  final int helpfulCount;
  final bool isVerifiedPurchase;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ReviewEntity({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.itemId,
    required this.itemType,
    required this.rating,
    this.comment,
    this.images,
    this.helpfulCount = 0,
    this.isVerifiedPurchase = false,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userAvatar,
        itemId,
        itemType,
        rating,
        comment,
        images,
        helpfulCount,
        isVerifiedPurchase,
        createdAt,
        updatedAt,
      ];
}

