import 'package:mwanachuo/features/shared/notifications/domain/entities/notification_entity.dart';

/// Notification model for the data layer
class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.title,
    required super.message,
    super.isRead,
    super.actionUrl,
    super.imageUrl,
    super.metadata,
    required super.createdAt,
    super.readAt,
  });

  /// Create a NotificationModel from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: _notificationTypeFromString(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      actionUrl: json['action_url'] as String?,
      imageUrl: json['image_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
    );
  }

  /// Convert NotificationModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': _notificationTypeToString(type),
      'title': title,
      'message': message,
      'is_read': isRead,
      'action_url': actionUrl,
      'image_url': imageUrl,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  static NotificationType _notificationTypeFromString(String type) {
    switch (type) {
      case 'message':
        return NotificationType.message;
      case 'order':
        return NotificationType.order;
      case 'review':
        return NotificationType.review;
      case 'promotion':
        return NotificationType.promotion;
      case 'system':
        return NotificationType.system;
      case 'seller_request':
        return NotificationType.sellerRequest;
      case 'product_approval':
        return NotificationType.productApproval;
      default:
        return NotificationType.system;
    }
  }

  static String _notificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return 'message';
      case NotificationType.order:
        return 'order';
      case NotificationType.review:
        return 'review';
      case NotificationType.promotion:
        return 'promotion';
      case NotificationType.system:
        return 'system';
      case NotificationType.sellerRequest:
        return 'seller_request';
      case NotificationType.productApproval:
        return 'product_approval';
    }
  }
}

