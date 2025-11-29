import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/messages/domain/entities/message_entity.dart';

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
  final String? listingId;
  final String? listingType; // 'product', 'service', 'accommodation'
  final String? listingTitle;
  final String? listingImageUrl;
  final String? listingPrice;
  final String? listingPriceType; // For accommodations: 'per_month', etc.

  const GetOrCreateConversationEvent({
    required this.otherUserId,
    this.listingId,
    this.listingType,
    this.listingTitle,
    this.listingImageUrl,
    this.listingPrice,
    this.listingPriceType,
  });

  @override
  List<Object?> get props => [
        otherUserId,
        listingId,
        listingType,
        listingTitle,
        listingImageUrl,
        listingPrice,
        listingPriceType,
      ];
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
  final Map<String, dynamic>? metadata;

  const SendMessageEvent({
    required this.conversationId,
    required this.content,
    this.imageUrl,
    this.repliedToMessageId,
    this.metadata,
  });

  @override
  List<Object?> get props => [
    conversationId,
    content,
    imageUrl,
    repliedToMessageId,
    metadata,
  ];
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

  const SearchMessagesEvent({required this.query, this.limit});

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

  const DeleteConversationEvent({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

class DeleteMessageForUserEvent extends MessageEvent {
  final String messageId;

  const DeleteMessageForUserEvent({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

class MessagesUpdatedEvent extends MessageEvent {
  final List<MessageEntity> messages;
  final String conversationId;

  const MessagesUpdatedEvent({
    required this.messages,
    required this.conversationId,
  });

  @override
  List<Object?> get props => [messages, conversationId];
}
