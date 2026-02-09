import 'package:mwanachuo/features/shared/reviews/domain/entities/review_stats_entity.dart';

/// Review stats model for the data layer
class ReviewStatsModel extends ReviewStatsEntity {
  const ReviewStatsModel({
    required super.itemId,
    required super.averageRating,
    required super.totalReviews,
    required super.ratingDistribution,
  });

  /// Create a ReviewStatsModel from JSON
  factory ReviewStatsModel.fromJson(Map<String, dynamic> json) {
    final distributionData =
        json['rating_distribution'] as Map<String, dynamic>;
    final distribution = <int, int>{};

    distributionData.forEach((key, value) {
      final rating = int.tryParse(key);
      if (rating != null) {
        distribution[rating] = (value as num).toInt();
      }
    });

    // Ensure all ratings 1-5 exist in the map
    for (int i = 1; i <= 5; i++) {
      distribution.putIfAbsent(i, () => 0);
    }

    return ReviewStatsModel(
      itemId: json['item_id'] as String,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      ratingDistribution: distribution,
    );
  }

  /// Convert ReviewStatsModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'rating_distribution': ratingDistribution,
    };
  }

  /// Calculate stats from a list of reviews
  factory ReviewStatsModel.fromReviews({
    required String itemId,
    required List<Map<String, dynamic>> reviews,
  }) {
    if (reviews.isEmpty) {
      return ReviewStatsModel(
        itemId: itemId,
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      );
    }

    final distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    double totalRating = 0.0;

    for (final review in reviews) {
      final rating = (review['rating'] as num).toInt();
      distribution[rating] = (distribution[rating] ?? 0) + 1;
      totalRating += rating;
    }

    return ReviewStatsModel(
      itemId: itemId,
      averageRating: totalRating / reviews.length,
      totalReviews: reviews.length,
      ratingDistribution: distribution,
    );
  }
}
