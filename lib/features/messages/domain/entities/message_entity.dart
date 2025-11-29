import 'package:equatable/equatable.dart';

/// Message status enum for WhatsApp-style ticks
enum MessageStatus {
  sent,      // One tick (message sent)
  delivered, // Two ticks (message delivered to recipient)
  read,      // Two blue ticks (message read by recipient)
}

/// Message entity representing a chat message
class MessageEntity extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final String? repliedToMessageId;
  final List<String> deletedBy;

  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.imageUrl,
    this.metadata,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.deliveredAt,
    this.repliedToMessageId,
    this.deletedBy = const [],
  });

  /// Get message status for display
  MessageStatus get status {
    if (readAt != null) return MessageStatus.read;
    if (deliveredAt != null) return MessageStatus.delivered;
    return MessageStatus.sent;
  }

  /// Check if message is deleted for a specific user
  bool isDeletedForUser(String userId) {
    return deletedBy.contains(userId);
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        senderName,
        senderAvatar,
        content,
        imageUrl,
        metadata,
        isRead,
        createdAt,
        readAt,
        deliveredAt,
        repliedToMessageId,
        deletedBy,
      ];
}

