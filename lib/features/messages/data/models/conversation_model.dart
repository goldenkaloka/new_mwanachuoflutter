import 'package:mwanachuo/features/messages/domain/entities/conversation_entity.dart';

class ConversationModel extends ConversationEntity {
  const ConversationModel({
    required super.id,
    required super.userId,
    required super.otherUserId,
    required super.otherUserName,
    super.otherUserAvatar,
    super.lastMessage,
    super.lastMessageTime,
    super.unreadCount,
    super.isOnline,
    super.lastSeenAt,
    required super.createdAt,
    super.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    // Helper to handle null values properly
    String? getNullableString(dynamic value) {
      if (value == null || value == 'null') return null;
      return value as String?;
    }

    return ConversationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      otherUserId: json['other_user_id'] as String,
      otherUserName: json['other_user_name'] as String? ?? 'Unknown',
      otherUserAvatar: getNullableString(json['other_user_avatar']),
      lastMessage: getNullableString(json['last_message']),
      lastMessageTime: json['last_message_time'] != null && json['last_message_time'] != 'null'
          ? DateTime.parse(json['last_message_time'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeenAt: json['last_seen_at'] != null && json['last_seen_at'] != 'null'
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null && json['updated_at'] != 'null'
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'other_user_id': otherUserId,
      'other_user_name': otherUserName,
      'other_user_avatar': otherUserAvatar,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'unread_count': unreadCount,
      'is_online': isOnline,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

