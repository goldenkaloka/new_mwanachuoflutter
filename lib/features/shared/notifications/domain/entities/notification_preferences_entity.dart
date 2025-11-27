import 'package:equatable/equatable.dart';

/// Notification preferences entity
class NotificationPreferencesEntity extends Equatable {
  final String id;
  final String userId;
  final bool pushEnabled;
  final bool messagesEnabled;
  final bool reviewsEnabled;
  final bool listingsEnabled;
  final bool promotionsEnabled;
  final bool sellerRequestsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationPreferencesEntity({
    required this.id,
    required this.userId,
    this.pushEnabled = true,
    this.messagesEnabled = true,
    this.reviewsEnabled = true,
    this.listingsEnabled = true,
    this.promotionsEnabled = true,
    this.sellerRequestsEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        pushEnabled,
        messagesEnabled,
        reviewsEnabled,
        listingsEnabled,
        promotionsEnabled,
        sellerRequestsEnabled,
        createdAt,
        updatedAt,
      ];
}

