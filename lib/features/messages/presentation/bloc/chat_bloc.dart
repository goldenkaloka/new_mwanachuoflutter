import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/messages/domain/entities/message.dart';
import 'package:mwanachuo/features/messages/domain/repositories/messages_repository.dart';

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object> get props => [];
}

class LoadMessages extends ChatEvent {
  final String conversationId;
  const LoadMessages(this.conversationId);
  @override
  List<Object> get props => [conversationId];
}

class SendMessage extends ChatEvent {
  final String conversationId;
  final String content;
  final MessageType type;
  final Map<String, dynamic> metadata;
  final String? otherUserId; // Required if conversationId is 'new'

  const SendMessage({
    required this.conversationId,
    required this.content,
    this.type = MessageType.text,
    this.metadata = const {},
    this.otherUserId,
  });

  @override
  List<Object> get props => [
    conversationId,
    content,
    type,
    metadata,
    if (otherUserId != null) otherUserId!,
  ];
}

class StartChat extends ChatEvent {
  final String otherUserId;
  const StartChat(this.otherUserId);
  @override
  List<Object> get props => [otherUserId];
}

class MessagesUpdated extends ChatEvent {
  final List<Message> messages;
  final String conversationId;
  const MessagesUpdated(this.messages, this.conversationId);
  @override
  List<Object> get props => [messages, conversationId];
}

class MarkAsRead extends ChatEvent {
  final String conversationId;
  const MarkAsRead(this.conversationId);
  @override
  List<Object> get props => [conversationId];
}

// States
abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<Message> messages;
  final String conversationId;
  const ChatLoaded(this.messages, this.conversationId);
  @override
  List<Object> get props => [messages, conversationId];
}

class ChatConversationInitiated extends ChatState {
  final String conversationId;
  const ChatConversationInitiated(this.conversationId);
  @override
  List<Object> get props => [conversationId];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final MessagesRepository _repository;
  StreamSubscription? _subscription;

  ChatBloc(this._repository) : super(ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<StartChat>(_onStartChat);
    on<MessagesUpdated>(_onMessagesUpdated);
    on<MarkAsRead>(_onMarkAsRead);
  }

  void _onLoadMessages(LoadMessages event, Emitter<ChatState> emit) {
    if (event.conversationId == 'new') {
      emit(const ChatLoaded([], 'new'));
      return;
    }
    emit(ChatLoading());
    _subscription?.cancel();
    _subscription = _repository
        .getMessagesStream(event.conversationId)
        .listen(
          (messages) {
            add(MessagesUpdated(messages, event.conversationId));
          },
          onError: (e) {
            // Handle error
          },
        );
  }

  Future<void> _onStartChat(StartChat event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      final conversation = await _repository.initiateConversation(
        event.otherUserId,
      );
      emit(ChatConversationInitiated(conversation.id));
      add(LoadMessages(conversation.id));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  void _onMessagesUpdated(MessagesUpdated event, Emitter<ChatState> emit) {
    emit(ChatLoaded(event.messages, event.conversationId));
    // Automatically mark as read when messages are loaded/updated
    if (event.messages.isNotEmpty) {
      add(MarkAsRead(event.messages.first.conversationId));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      String convId = event.conversationId;

      // Handle new conversation initiation
      if (convId == 'new' && event.otherUserId != null) {
        final conversation = await _repository.initiateConversation(
          event.otherUserId!,
        );
        convId = conversation.id;
        // Start loading the new conversation
        add(LoadMessages(convId));
      }

      if (convId == 'new') return; // Should not happen if otherUserId provided

      await _repository.sendMessage(
        conversationId: convId,
        content: event.content,
        type: event.type,
        metadata: event.metadata,
      );
    } catch (e) {
      // Optionally emit error but usually optimistic UI handles this
    }
  }

  Future<void> _onMarkAsRead(MarkAsRead event, Emitter<ChatState> emit) async {
    if (event.conversationId == 'new') return;
    await _repository.markAsRead(event.conversationId);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
