import 'package:mwanachuo/features/messages/domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.content,
    required super.type,
    required super.metadata,
    required super.isRead,
    required super.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      metadata: json['metadata'] ?? {},
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'type': type,
      'metadata': metadata,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
