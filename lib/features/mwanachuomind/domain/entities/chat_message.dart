import 'package:equatable/equatable.dart';

enum MessageSender { user, ai }

class ChatMessage extends Equatable {
  final String id;
  final String content;
  final MessageSender sender;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, content, sender, timestamp];
}
