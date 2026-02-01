import 'package:equatable/equatable.dart';

/// Product entity representing a marketplace product
class ProductEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final List<String> images;
  final String sellerId;
  final String sellerName;
  final String sellerPhone;
  final String? sellerAvatar;
  final List<String> universityIds;
  final String location;
  final bool isActive;
  final bool isFeatured;
  final int viewCount;
  final double? rating;
  final int? reviewCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;
  final double? oldPrice;

  const ProductEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.images,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
    this.sellerAvatar,
    required this.universityIds,
    required this.location,
    this.isActive = true,
    this.isFeatured = false,
    this.viewCount = 0,
    this.rating,
    this.reviewCount,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
    this.oldPrice,
  });

  int? get discountPercentage {
    if (oldPrice != null && oldPrice! > price) {
      return (((oldPrice! - price) / oldPrice!) * 100).round();
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    price,
    category,
    condition,
    images,
    sellerId,
    sellerName,
    sellerAvatar,
    universityIds,
    location,
    isActive,
    isFeatured,
    viewCount,
    rating,
    reviewCount,
    createdAt,
    updatedAt,
    metadata,
  ];
}
