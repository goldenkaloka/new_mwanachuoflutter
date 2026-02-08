import 'package:mwanachuo/features/auth/domain/entities/user_entity.dart';
import 'package:mwanachuo/features/messages/domain/entities/conversation.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.participants,
    super.lastMessage,
    super.lastMessageAt,
    required super.updatedAt,
    super.participantsData,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      participants: List<String>.from(json['participants'] ?? []),
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ConversationModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageAt,
    DateTime? updatedAt,
    List<UserEntity>? participantsData,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      updatedAt: updatedAt ?? this.updatedAt,
      participantsData: participantsData ?? this.participantsData,
    );
  }
}
