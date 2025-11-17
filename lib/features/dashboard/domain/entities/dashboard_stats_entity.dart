import 'package:equatable/equatable.dart';

class DashboardStatsEntity extends Equatable {
  final int totalProducts;
  final int totalServices;
  final int totalAccommodations;
  final int activeListings;
  final int totalViews;
  final double averageRating;
  final int totalReviews;
  final int unreadMessages;

  const DashboardStatsEntity({
    this.totalProducts = 0,
    this.totalServices = 0,
    this.totalAccommodations = 0,
    this.activeListings = 0,
    this.totalViews = 0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.unreadMessages = 0,
  });

  @override
  List<Object?> get props => [
        totalProducts,
        totalServices,
        totalAccommodations,
        activeListings,
        totalViews,
        averageRating,
        totalReviews,
        unreadMessages,
      ];
}

