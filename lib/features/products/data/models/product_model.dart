import 'package:mwanachuo/features/products/domain/entities/product_entity.dart';

/// Product model for the data layer
class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.title,
    required super.description,
    required super.price,
    required super.category,
    required super.condition,
    required super.images,
    required super.sellerId,
    required super.sellerName,
    required super.sellerPhone,
    super.sellerAvatar,
    required super.universityIds,
    required super.location,
    super.isActive,
    super.isFeatured,
    super.viewCount,
    super.rating,
    super.reviewCount,
    required super.createdAt,
    super.updatedAt,
    super.metadata,
    super.oldPrice,
  });

  /// Create a ProductModel from JSON
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String,
      condition: json['condition'] as String,
      images: List<String>.from(json['images'] as List? ?? []),
      sellerId: json['seller_id'] as String,
      sellerName: json['seller_name'] as String? ?? 'Unknown',
      sellerPhone: json['seller_phone'] as String? ?? '',
      sellerAvatar: json['seller_avatar'] as String?,
      universityIds: List<String>.from(json['university_ids'] as List? ?? []),
      location: json['location'] as String,
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      viewCount: json['view_count'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      oldPrice:
          (json['metadata'] as Map<String, dynamic>?)?['old_price'] != null
          ? (json['metadata']['old_price'] as num).toDouble()
          : null,
    );
  }

  /// Convert ProductModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      'images': images,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'seller_phone': sellerPhone,
      'seller_avatar': sellerAvatar,
      'university_ids': universityIds,
      'location': location,
      'is_active': isActive,
      'is_featured': isFeatured,
      'view_count': viewCount,
      'rating': rating,
      'review_count': reviewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': {...?metadata, if (oldPrice != null) 'old_price': oldPrice},
    };
  }
}
