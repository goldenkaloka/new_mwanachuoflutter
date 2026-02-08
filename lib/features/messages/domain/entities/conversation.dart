import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/auth/domain/entities/user_entity.dart';

class Conversation extends Equatable {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime updatedAt;
  final List<UserEntity>? participantsData;

  const Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageAt,
    required this.updatedAt,
    this.participantsData,
  });

  @override
  List<Object?> get props => [
    id,
    participants,
    lastMessage,
    lastMessageAt,
    updatedAt,
    participantsData,
  ];
}
