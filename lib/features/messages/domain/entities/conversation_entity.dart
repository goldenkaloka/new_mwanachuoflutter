import 'package:equatable/equatable.dart';

/// Conversation entity representing a chat conversation
class ConversationEntity extends Equatable {
  final String id;
  final String userId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ConversationEntity({
    required this.id,
    required this.userId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.lastSeenAt,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if this is a self-conversation (messaging yourself)
  /// In self-conversations, we should never show unread badges
  bool get isSelfConversation => userId == otherUserId;

  /// Get the effective unread count (0 for self-conversations)
  /// This ensures self-conversations never show as unread
  int get effectiveUnreadCount => isSelfConversation ? 0 : unreadCount;

  /// Create a copy of this entity with updated fields
  ConversationEntity copyWith({
    String? id,
    String? userId,
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatar,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isOnline,
    DateTime? lastSeenAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatar: otherUserAvatar ?? this.otherUserAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        otherUserId,
        otherUserName,
        otherUserAvatar,
        lastMessage,
        lastMessageTime,
        unreadCount,
        isOnline,
        lastSeenAt,
        createdAt,
        updatedAt,
      ];
}

