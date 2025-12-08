import 'package:equatable/equatable.dart';

/// Entity representing criteria for fetching recommendations
class RecommendationCriteriaEntity extends Equatable {
  final String? category;
  final String? sellerId;
  final List<String>? universityIds;
  final double? price;
  final double priceRangePercent; // default 0.2 (20%)
  final String? location;
  final int limit; // default 8

  const RecommendationCriteriaEntity({
    this.category,
    this.sellerId,
    this.universityIds,
    this.price,
    this.priceRangePercent = 0.2,
    this.location,
    this.limit = 8,
  });

  RecommendationCriteriaEntity copyWith({
    String? category,
    String? sellerId,
    List<String>? universityIds,
    double? price,
    double? priceRangePercent,
    String? location,
    int? limit,
  }) {
    return RecommendationCriteriaEntity(
      category: category ?? this.category,
      sellerId: sellerId ?? this.sellerId,
      universityIds: universityIds ?? this.universityIds,
      price: price ?? this.price,
      priceRangePercent: priceRangePercent ?? this.priceRangePercent,
      location: location ?? this.location,
      limit: limit ?? this.limit,
    );
  }

  @override
  List<Object?> get props => [
    category,
    sellerId,
    universityIds,
    price,
    priceRangePercent,
    location,
    limit,
  ];
}







