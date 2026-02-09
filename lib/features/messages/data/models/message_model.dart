import 'package:mwanachuo/features/messages/domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.content,
    required super.type,
    super.metadata,
    super.replyToId,
    required super.createdAt,
    super.isRead,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      conversationId: map['conversation_id'],
      senderId: map['sender_id'],
      content: map['content'] ?? '',
      type: _mapToType(map['type']),
      metadata: map['metadata'] ?? {},
      replyToId: map['reply_to_id'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      isRead: map['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'type': _typeToString(type),
      'metadata': metadata,
      'reply_to_id': replyToId,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  static MessageType _mapToType(String? type) => MessageType.fromDbString(type);

  static String _typeToString(MessageType type) => type.toDbString;
}
