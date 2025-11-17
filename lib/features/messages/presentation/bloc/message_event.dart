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
  final String? repliedToMessageId;

  const SendMessageEvent({
    required this.conversationId,
    required this.content,
    this.imageUrl,
    this.repliedToMessageId,
  });

  @override
  List<Object?> get props => [conversationId, content, imageUrl, repliedToMessageId];
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

class SendTypingIndicatorEvent extends MessageEvent {
  final String conversationId;
  final bool isTyping;

  const SendTypingIndicatorEvent({
    required this.conversationId,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [conversationId, isTyping];
}

class UploadImageEvent extends MessageEvent {
  final String filePath;

  const UploadImageEvent({required this.filePath});

  @override
  List<Object?> get props => [filePath];
}

class SearchMessagesEvent extends MessageEvent {
  final String query;
  final int? limit;

  const SearchMessagesEvent({
    required this.query,
    this.limit,
  });

  @override
  List<Object?> get props => [query, limit];
}

class LoadMoreMessagesEvent extends MessageEvent {
  final String conversationId;

  const LoadMoreMessagesEvent({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class RetryMessageEvent extends MessageEvent {
  final String conversationId;
  final String content;
  final String? imageUrl;
  final int? retryCount;

  const RetryMessageEvent({
    required this.conversationId,
    required this.content,
    this.imageUrl,
    this.retryCount,
  });

  @override
  List<Object?> get props => [conversationId, content, imageUrl, retryCount];
}

class DeleteConversationEvent extends MessageEvent {
  final String conversationId;

  const DeleteConversationEvent({
    required this.conversationId,
  });

  @override
  List<Object?> get props => [conversationId];
}

class DeleteMessageForUserEvent extends MessageEvent {
  final String messageId;

  const DeleteMessageForUserEvent({
    required this.messageId,
  });

  @override
  List<Object?> get props => [messageId];
}
