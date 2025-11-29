import 'package:mwanachuo/features/shared/notifications/domain/entities/notification_preferences_entity.dart';

/// Notification preferences model
class NotificationPreferencesModel extends NotificationPreferencesEntity {
  const NotificationPreferencesModel({
    required super.id,
    required super.userId,
    super.pushEnabled,
    super.messagesEnabled,
    super.reviewsEnabled,
    super.listingsEnabled,
    super.promotionsEnabled,
    super.sellerRequestsEnabled,
    super.quietHoursStart,
    super.quietHoursEnd,
    super.groupNotifications,
    super.groupByCategory,
    super.soundEnabled,
    super.vibrationEnabled,
    super.badgeEnabled,
    super.inAppBannerEnabled,
    super.categoryPreferences,
    required super.createdAt,
    required super.updatedAt,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    // Parse category preferences
    final categoryPrefsJson = json['category_preferences'] as Map<String, dynamic>?;
    final categoryPreferences = <String, CategoryPreference>{};
    
    if (categoryPrefsJson != null) {
      categoryPrefsJson.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          categoryPreferences[key] = CategoryPreference.fromJson(value);
        }
      });
    }

    // Parse quiet hours
    DateTime? quietHoursStart;
    DateTime? quietHoursEnd;
    if (json['quiet_hours_start'] != null) {
      final timeStr = json['quiet_hours_start'] as String;
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        quietHoursStart = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      }
    }
    if (json['quiet_hours_end'] != null) {
      final timeStr = json['quiet_hours_end'] as String;
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        quietHoursEnd = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      }
    }

    return NotificationPreferencesModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      pushEnabled: json['push_enabled'] as bool? ?? true,
      messagesEnabled: json['messages_enabled'] as bool? ?? true,
      reviewsEnabled: json['reviews_enabled'] as bool? ?? true,
      listingsEnabled: json['listings_enabled'] as bool? ?? true,
      promotionsEnabled: json['promotions_enabled'] as bool? ?? true,
      sellerRequestsEnabled: json['seller_requests_enabled'] as bool? ?? true,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
      groupNotifications: json['group_notifications'] as bool? ?? true,
      groupByCategory: json['group_by_category'] as bool? ?? true,
      soundEnabled: json['sound_enabled'] as bool? ?? true,
      vibrationEnabled: json['vibration_enabled'] as bool? ?? true,
      badgeEnabled: json['badge_enabled'] as bool? ?? true,
      inAppBannerEnabled: json['in_app_banner_enabled'] as bool? ?? true,
      categoryPreferences: categoryPreferences,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    // Convert category preferences to JSON
    final categoryPrefsJson = <String, dynamic>{};
    categoryPreferences.forEach((key, value) {
      categoryPrefsJson[key] = value.toJson();
    });

    return {
      'id': id,
      'user_id': userId,
      'push_enabled': pushEnabled,
      'messages_enabled': messagesEnabled,
      'reviews_enabled': reviewsEnabled,
      'listings_enabled': listingsEnabled,
      'promotions_enabled': promotionsEnabled,
      'seller_requests_enabled': sellerRequestsEnabled,
      'quiet_hours_start': quietHoursStart?.toString().substring(11, 16), // HH:mm format
      'quiet_hours_end': quietHoursEnd?.toString().substring(11, 16),
      'group_notifications': groupNotifications,
      'group_by_category': groupByCategory,
      'sound_enabled': soundEnabled,
      'vibration_enabled': vibrationEnabled,
      'badge_enabled': badgeEnabled,
      'in_app_banner_enabled': inAppBannerEnabled,
      'category_preferences': categoryPrefsJson,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  NotificationPreferencesEntity toEntity() {
    return NotificationPreferencesEntity(
      id: id,
      userId: userId,
      pushEnabled: pushEnabled,
      messagesEnabled: messagesEnabled,
      reviewsEnabled: reviewsEnabled,
      listingsEnabled: listingsEnabled,
      promotionsEnabled: promotionsEnabled,
      sellerRequestsEnabled: sellerRequestsEnabled,
      quietHoursStart: quietHoursStart,
      quietHoursEnd: quietHoursEnd,
      groupNotifications: groupNotifications,
      groupByCategory: groupByCategory,
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      badgeEnabled: badgeEnabled,
      inAppBannerEnabled: inAppBannerEnabled,
      categoryPreferences: categoryPreferences,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

