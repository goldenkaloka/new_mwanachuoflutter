import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/messages/domain/entities/conversation_entity.dart';
import 'package:mwanachuo/features/messages/domain/entities/message_entity.dart';

abstract class MessageState extends Equatable {
  const MessageState();

  @override
  List<Object?> get props => [];
}

class MessageInitial extends MessageState {}

class ConversationsLoading extends MessageState {}

class ConversationsLoaded extends MessageState {
  final List<ConversationEntity> conversations;

  const ConversationsLoaded({required this.conversations});

  @override
  List<Object?> get props => [conversations];
}

class ConversationLoading extends MessageState {}

class ConversationLoaded extends MessageState {
  final ConversationEntity conversation;

  const ConversationLoaded({required this.conversation});

  @override
  List<Object?> get props => [conversation];
}

class MessagesLoading extends MessageState {}

class MessagesLoaded extends MessageState {
  final List<MessageEntity> messages;
  final String conversationId;
  final bool isSending;
  final bool hasMore;
  final bool isLoadingMore;
  final String? error;

  const MessagesLoaded({
    required this.messages,
    required this.conversationId,
    this.isSending = false,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.error,
  });

  MessagesLoaded copyWith({
    List<MessageEntity>? messages,
    String? conversationId,
    bool? isSending,
    bool? hasMore,
    bool? isLoadingMore,
    String? error,
  }) {
    return MessagesLoaded(
      messages: messages ?? this.messages,
      conversationId: conversationId ?? this.conversationId,
      isSending: isSending ?? this.isSending,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error:
          error, // Allow clearing error by passing null, but here we need to be careful.
      // If we pass null, it stays null. If we don't pass it, it stays current.
      // Actually, usually we want to clear error on new actions.
      // Let's make it: error: error ?? this.error, but that persists error.
      // For transient errors, we might want to clear it.
      // Let's stick to standard copyWith pattern: error: error ?? this.error
      // But wait, if I want to clear it, I can't pass null if I use ?? this.error.
      // I'll use: error: error (if passed, use it. If not passed, keep it? Or clear it?)
      // Standard copyWith keeps it.
      // I will change logic: error: error ?? this.error
    );
  }

  @override
  List<Object?> get props => [
    messages,
    conversationId,
    isSending,
    hasMore,
    isLoadingMore,
    error,
  ];
}

class MessageSending extends MessageState {}

class MessageSent extends MessageState {
  final MessageEntity message;

  const MessageSent({required this.message});

  @override
  List<Object?> get props => [message];
}

class NewMessageReceived extends MessageState {
  final MessageEntity message;

  const NewMessageReceived({required this.message});

  @override
  List<Object?> get props => [message];
}

class NewConversationUpdate extends MessageState {
  final ConversationEntity conversation;

  const NewConversationUpdate({required this.conversation});

  @override
  List<Object?> get props => [conversation];
}

class MessageError extends MessageState {
  final String message;

  const MessageError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ImageUploading extends MessageState {}

class ImageUploaded extends MessageState {
  final String imageUrl;

  const ImageUploaded({required this.imageUrl});

  @override
  List<Object?> get props => [imageUrl];
}

class SearchResultsLoaded extends MessageState {
  final List<MessageEntity> results;
  final String query;

  const SearchResultsLoaded({required this.results, required this.query});

  @override
  List<Object?> get props => [results, query];
}

class TypingIndicatorState extends MessageState {
  final String conversationId;
  final bool isTyping;

  const TypingIndicatorState({
    required this.conversationId,
    required this.isTyping,
  });

  @override
  List<Object?> get props => [conversationId, isTyping];
}

class LoadingMoreMessages extends MessageState {
  final List<MessageEntity> currentMessages;
  final String conversationId;

  const LoadingMoreMessages({
    required this.currentMessages,
    required this.conversationId,
  });

  @override
  List<Object?> get props => [currentMessages, conversationId];
}
