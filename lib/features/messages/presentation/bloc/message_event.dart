import 'package:equatable/equatable.dart';

abstract class MessageEvent extends Equatable {
  const MessageEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversationsEvent extends MessageEvent {
  final int? limit;
  final int? offset;
  final bool forceRefresh;

  const LoadConversationsEvent({
    this.limit,
    this.offset,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [limit, offset, forceRefresh];
}

class GetOrCreateConversationEvent extends MessageEvent {
  final String otherUserId;

  const GetOrCreateConversationEvent({required this.otherUserId});

  @override
  List<Object?> get props => [otherUserId];
}

class LoadMessagesEvent extends MessageEvent {
  final String conversationId;
  final int? limit;
  final int? offset;

  const LoadMessagesEvent({
    required this.conversationId,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [conversationId, limit, offset];
}

class SendMessageEvent extends MessageEvent {
  final String conversationId;
  final String content;
  final String? imageUrl;

  const SendMessageEvent({
    required this.conversationId,
    required this.content,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [conversationId, content, imageUrl];
}

class MarkMessagesAsReadEvent extends MessageEvent {
  final String conversationId;

  const MarkMessagesAsReadEvent({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class StartListeningToMessagesEvent extends MessageEvent {
  final String conversationId;

  const StartListeningToMessagesEvent({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class StartListeningToConversationsEvent extends MessageEvent {}

class StopListeningEvent extends MessageEvent {}
