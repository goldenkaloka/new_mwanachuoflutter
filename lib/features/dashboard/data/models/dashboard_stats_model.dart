import 'package:mwanachuo/features/dashboard/domain/entities/dashboard_stats_entity.dart';

class DashboardStatsModel extends DashboardStatsEntity {
  const DashboardStatsModel({
    super.totalProducts,
    super.totalServices,
    super.totalAccommodations,
    super.activeListings,
    super.totalViews,
    super.averageRating,
    super.totalReviews,
    super.unreadMessages,
    super.lastMessageTime,
    super.lastListingUpdateTime,
    super.lastReviewTime,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(String? dateStr) {
      if (dateStr == null) return null;
      try {
        return DateTime.parse(dateStr).toLocal();
      } catch (e) {
        return null;
      }
    }

    return DashboardStatsModel(
      totalProducts: json['total_products'] as int? ?? 0,
      totalServices: json['total_services'] as int? ?? 0,
      totalAccommodations: json['total_accommodations'] as int? ?? 0,
      activeListings: json['active_listings'] as int? ?? 0,
      totalViews: json['total_views'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      unreadMessages: json['unread_messages'] as int? ?? 0,
      lastMessageTime: parseDateTime(json['last_message_time'] as String?),
      lastListingUpdateTime: parseDateTime(json['last_listing_update_time'] as String?),
      lastReviewTime: parseDateTime(json['last_review_time'] as String?),
    );
  }
}
