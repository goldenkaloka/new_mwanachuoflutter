import 'package:equatable/equatable.dart';

/// Review statistics entity
class ReviewStatsEntity extends Equatable {
  final String itemId;
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // {5: 100, 4: 50, 3: 20, 2: 10, 1: 5}

  const ReviewStatsEntity({
    required this.itemId,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  /// Get percentage for a specific rating
  double getRatingPercentage(int rating) {
    if (totalReviews == 0) return 0.0;
    final count = ratingDistribution[rating] ?? 0;
    return (count / totalReviews) * 100;
  }

  @override
  List<Object?> get props => [
        itemId,
        averageRating,
        totalReviews,
        ratingDistribution,
      ];
}

