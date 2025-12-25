import 'package:mwanachuo/features/shared/search/domain/entities/search_result_entity.dart';

/// Search result model for the data layer
class SearchResultModel extends SearchResultEntity {
  const SearchResultModel({
    required super.id,
    required super.title,
    required super.description,
    required super.type,
    super.imageUrl,
    super.price,
    super.rating,
    super.reviewCount,
    super.location,
    super.sellerId,
    super.sellerName,
    super.createdAt,
  });

  /// Create a SearchResultModel from JSON
  factory SearchResultModel.fromJson(
    Map<String, dynamic> json,
    SearchResultType type,
  ) {
    return SearchResultModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: type,
      imageUrl: _extractImageUrl(json),
      price: (json['price'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
      location: json['location'] as String?,
      sellerId: json['seller_id'] as String? ?? json['user_id'] as String?,
      sellerName: json['seller_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Create a SearchResultModel from JSON stored in cache (includes type)
  factory SearchResultModel.fromCacheJson(Map<String, dynamic> json) {
    return SearchResultModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: _stringToType(json['type'] as String),
      imageUrl: json['image_url'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
      location: json['location'] as String?,
      sellerId: json['seller_id'] as String?,
      sellerName: json['seller_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  static String? _extractImageUrl(Map<String, dynamic> json) {
    // Try different fields where image might be stored
    if (json['image_url'] != null) {
      return json['image_url'] as String;
    }
    if (json['images'] != null && json['images'] is List) {
      final images = json['images'] as List;
      if (images.isNotEmpty) {
        return images.first as String;
      }
    }
    if (json['thumbnail_url'] != null) {
      return json['thumbnail_url'] as String;
    }
    return null;
  }

  /// Convert SearchResultModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': _typeToString(type),
      'image_url': imageUrl,
      'price': price,
      'rating': rating,
      'review_count': reviewCount,
      'location': location,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static String _typeToString(SearchResultType type) {
    switch (type) {
      case SearchResultType.product:
        return 'product';
      case SearchResultType.service:
        return 'service';
      case SearchResultType.accommodation:
        return 'accommodation';
    }
  }

  static SearchResultType _stringToType(String type) {
    switch (type) {
      case 'product':
        return SearchResultType.product;
      case 'service':
        return SearchResultType.service;
      case 'accommodation':
        return SearchResultType.accommodation;
      default:
        return SearchResultType.product;
    }
  }
}
