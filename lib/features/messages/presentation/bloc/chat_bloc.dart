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
  final String type;
  final Map<String, dynamic> metadata;

  const SendMessage({
    required this.conversationId,
    required this.content,
    this.type = 'text',
    this.metadata = const {},
  });

  @override
  List<Object> get props => [conversationId, content, type, metadata];
}

class StartConversation extends ChatEvent {
  final List<String> participantIds;
  const StartConversation(this.participantIds);
  @override
  List<Object> get props => [participantIds];
}

class MessagesUpdated extends ChatEvent {
  final List<Message> messages;
  final String conversationId;
  const MessagesUpdated(this.messages, this.conversationId);
  @override
  List<Object> get props => [messages, conversationId];
}

class UpdateMessage extends ChatEvent {
  final String messageId;
  final Map<String, dynamic> metadata;
  const UpdateMessage({required this.messageId, required this.metadata});
  @override
  List<Object> get props => [messageId, metadata];
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
  const ChatLoaded(this.messages, {required this.conversationId});
  @override
  List<Object> get props => [messages, conversationId];
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
  StreamSubscription? _messagesSubscription;

  ChatBloc(this._repository) : super(ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<StartConversation>(_onStartConversation);
    on<MessagesUpdated>(_onMessagesUpdated);
    on<UpdateMessage>(_onUpdateMessage);
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      await _messagesSubscription?.cancel();

      _messagesSubscription = _repository
          .getMessagesStream(event.conversationId)
          .listen((messages) {
            add(MessagesUpdated(messages, event.conversationId));
          });
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  void _onMessagesUpdated(MessagesUpdated event, Emitter<ChatState> emit) {
    emit(ChatLoaded(event.messages, conversationId: event.conversationId));
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
      // Handle error, maybe emit state with error but keep messages?
      // For now just error state
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onStartConversation(
    StartConversation event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      final conversation = await _repository.createConversation(
        event.participantIds,
      );
      // Once created, load messages for it
      add(LoadMessages(conversation.id));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onUpdateMessage(
    UpdateMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _repository.updateMessage(event.messageId, event.metadata);
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
