import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String type; // 'text', 'offer', 'image'
  final Map<String, dynamic> metadata;
  final bool isRead;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.metadata,
    required this.isRead,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    content,
    type,
    metadata,
    isRead,
    createdAt,
  ];
}
