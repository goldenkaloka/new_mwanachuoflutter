import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/messages/domain/entities/conversation.dart';
import 'package:mwanachuo/features/messages/domain/repositories/messages_repository.dart';

// Events
abstract class ConversationsEvent extends Equatable {
  const ConversationsEvent();
  @override
  List<Object> get props => [];
}

class LoadConversations extends ConversationsEvent {}

// States
abstract class ConversationsState extends Equatable {
  const ConversationsState();
  @override
  List<Object> get props => [];
}

class ConversationsInitial extends ConversationsState {}
class ConversationsLoading extends ConversationsState {}
class ConversationsLoaded extends ConversationsState {
  final List<Conversation> conversations;
  const ConversationsLoaded(this.conversations);
  @override
  List<Object> get props => [conversations];
}
class ConversationsError extends ConversationsState {
  final String message;
  const ConversationsError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final MessagesRepository _repository;

  ConversationsBloc(this._repository) : super(ConversationsInitial()) {
    on<LoadConversations>(_onLoadConversations);
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(ConversationsLoading());
    try {
      final conversations = await _repository.getConversations();
      emit(ConversationsLoaded(conversations));
    } catch (e) {
      emit(ConversationsError(e.toString()));
    }
  }
}
