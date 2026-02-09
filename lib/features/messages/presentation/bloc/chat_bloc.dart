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

  const SendMessage({
    required this.conversationId,
    required this.content,
    this.type = MessageType.text,
    this.metadata = const {},
  });

  @override
  List<Object> get props => [conversationId, content, type, metadata];
}

class StartChat extends ChatEvent {
  final String otherUserId;
  const StartChat(this.otherUserId);
  @override
  List<Object> get props => [otherUserId];
}

class MessagesUpdated extends ChatEvent {
  final List<Message> messages;
  const MessagesUpdated(this.messages);
  @override
  List<Object> get props => [messages];
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
  const ChatLoaded(this.messages);
  @override
  List<Object> get props => [messages];
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
    emit(ChatLoading());
    _subscription?.cancel();
    _subscription = _repository
        .getMessagesStream(event.conversationId)
        .listen(
          (messages) {
            add(MessagesUpdated(messages));
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
      add(LoadMessages(conversation.id));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  void _onMessagesUpdated(MessagesUpdated event, Emitter<ChatState> emit) {
    emit(ChatLoaded(event.messages));
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
      await _repository.sendMessage(
        conversationId: event.conversationId,
        content: event.content,
        type: event.type,
        metadata: event.metadata,
      );
    } catch (e) {
      // Optionally emit error but usually optimistic UI handles this
    }
  }

  Future<void> _onMarkAsRead(MarkAsRead event, Emitter<ChatState> emit) async {
    await _repository.markAsRead(event.conversationId);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
