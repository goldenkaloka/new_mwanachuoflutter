import 'package:equatable/equatable.dart';

import 'package:mwanachuo/features/auth/domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final UserEntity user;

  const Authenticated(this.user);

  @override
  List<Object> get props => [user];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

class ProfileUpdated extends AuthState {
  final UserEntity user;

  const ProfileUpdated(this.user);

  @override
  List<Object> get props => [user];
}

class RegistrationCompleted extends AuthState {
  const RegistrationCompleted();
}

class RegistrationIncomplete extends AuthState {
  const RegistrationIncomplete();
}

class RegistrationCheckCompleted extends AuthState {
  final bool isCompleted;

  const RegistrationCheckCompleted(this.isCompleted);

  @override
  List<Object> get props => [isCompleted];
}

class PasswordResetSent extends AuthState {
  const PasswordResetSent();
}
