import 'package:mwanachuo/features/auth/data/models/user_model.dart';
import 'package:mwanachuo/features/messages/data/models/message_model.dart';
import 'package:mwanachuo/features/messages/domain/entities/conversation.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    super.lastMessageId,
    super.lastMessageAt,
    super.lastMessage,
    required super.participantIds,
    super.participantsData,
    required super.createdAt,
    required super.updatedAt,
    super.unreadCount,
  });

  factory ConversationModel.fromMap(
    Map<String, dynamic> map, {
    List<Map<String, dynamic>>? participants,
  }) {
    final participantListData =
        participants?.map((p) => UserModel.fromJson(p)).toList() ?? [];
    final participantIds = participantListData.map((p) => p.id).toList();

    return ConversationModel(
      id: map['id'],
      lastMessageId: map['last_message_id'],
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'])
          : null,
      lastMessage: map['last_message'] != null
          ? MessageModel.fromMap(map['last_message'])
          : null,
      participantIds: participantIds,
      participantsData: participantListData,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
      unreadCount: map['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'last_message_id': lastMessageId,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
