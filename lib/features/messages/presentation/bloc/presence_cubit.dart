import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/auth/data/models/user_model.dart';
import 'package:mwanachuo/features/messages/domain/repositories/messages_repository.dart';

abstract class PresenceState extends Equatable {
  const PresenceState();
  @override
  List<Object?> get props => [];
}

class PresenceInitial extends PresenceState {}

class PresenceLoaded extends PresenceState {
  final UserModel user;
  const PresenceLoaded(this.user);
  @override
  List<Object?> get props => [user];
}

class PresenceError extends PresenceState {
  final String message;
  const PresenceError(this.message);
  @override
  List<Object?> get props => [message];
}

class PresenceCubit extends Cubit<PresenceState> {
  final MessagesRepository _repository;
  StreamSubscription? _subscription;

  PresenceCubit(this._repository) : super(PresenceInitial());

  void subscribeToUserPresence(String userId) {
    _subscription?.cancel();
    _subscription = _repository
        .getUserStream(userId)
        .listen(
          (user) {
            emit(PresenceLoaded(user));
          },
          onError: (error) {
            emit(PresenceError(error.toString()));
          },
        );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
