import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/auth/data/models/user_model.dart';
import 'message.dart';

class Conversation extends Equatable {
  final String id;
  final String? lastMessageId;
  final DateTime? lastMessageAt;
  final Message? lastMessage;
  final List<String> participantIds;
  final List<UserModel> participantsData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;

  const Conversation({
    required this.id,
    this.lastMessageId,
    this.lastMessageAt,
    this.lastMessage,
    required this.participantIds,
    this.participantsData = const [],
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [
    id,
    lastMessageId,
    lastMessageAt,
    lastMessage,
    participantIds,
    participantsData,
    createdAt,
    updatedAt,
    unreadCount,
  ];

  Conversation copyWith({
    String? id,
    String? lastMessageId,
    DateTime? lastMessageAt,
    Message? lastMessage,
    List<String>? participantIds,
    List<UserModel>? participantsData,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? unreadCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      participantIds: participantIds ?? this.participantIds,
      participantsData: participantsData ?? this.participantsData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
