import 'package:equatable/equatable.dart';

/// Enum for notification types
enum NotificationType {
  message,
  order,
  review,
  promotion,
  system,
  sellerRequest,
  productApproval,
}

/// Notification entity representing a user notification
class NotificationEntity extends Equatable {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final String? actionUrl;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    this.actionUrl,
    this.imageUrl,
    this.metadata,
    required this.createdAt,
    this.readAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        message,
        isRead,
        actionUrl,
        imageUrl,
        metadata,
        createdAt,
        readAt,
      ];
}

