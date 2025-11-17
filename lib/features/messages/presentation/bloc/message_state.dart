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

  const MessagesLoaded({
    required this.messages,
    required this.conversationId,
    this.isSending = false,
  });

  MessagesLoaded copyWith({
    List<MessageEntity>? messages,
    String? conversationId,
    bool? isSending,
  }) {
    return MessagesLoaded(
      messages: messages ?? this.messages,
      conversationId: conversationId ?? this.conversationId,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => [messages, conversationId, isSending];
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

