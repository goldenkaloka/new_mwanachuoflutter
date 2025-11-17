import 'package:equatable/equatable.dart';

/// Enum for search result types
enum SearchResultType {
  product,
  service,
  accommodation,
}

/// Search result entity representing a search result item
class SearchResultEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final SearchResultType type;
  final String? imageUrl;
  final double? price;
  final double? rating;
  final int? reviewCount;
  final String? location;
  final String? sellerId;
  final String? sellerName;
  final DateTime? createdAt;

  const SearchResultEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.imageUrl,
    this.price,
    this.rating,
    this.reviewCount,
    this.location,
    this.sellerId,
    this.sellerName,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        imageUrl,
        price,
        rating,
        reviewCount,
        location,
        sellerId,
        sellerName,
        createdAt,
      ];
}

