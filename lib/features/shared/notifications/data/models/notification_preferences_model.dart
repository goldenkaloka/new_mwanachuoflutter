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
    required super.createdAt,
    required super.updatedAt,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      pushEnabled: json['push_enabled'] as bool? ?? true,
      messagesEnabled: json['messages_enabled'] as bool? ?? true,
      reviewsEnabled: json['reviews_enabled'] as bool? ?? true,
      listingsEnabled: json['listings_enabled'] as bool? ?? true,
      promotionsEnabled: json['promotions_enabled'] as bool? ?? true,
      sellerRequestsEnabled: json['seller_requests_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'push_enabled': pushEnabled,
      'messages_enabled': messagesEnabled,
      'reviews_enabled': reviewsEnabled,
      'listings_enabled': listingsEnabled,
      'promotions_enabled': promotionsEnabled,
      'seller_requests_enabled': sellerRequestsEnabled,
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
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

