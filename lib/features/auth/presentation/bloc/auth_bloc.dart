import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/auth/domain/usecases/check_registration_completion.dart';
import 'package:mwanachuo/features/auth/domain/usecases/complete_registration.dart';
import 'package:mwanachuo/features/auth/domain/usecases/get_current_user.dart';

import 'package:mwanachuo/features/auth/domain/usecases/sign_in.dart';
import 'package:mwanachuo/features/auth/domain/usecases/sign_out.dart';
import 'package:mwanachuo/features/auth/domain/usecases/sign_up.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignIn signIn;
  final SignUp signUp;
  final SignOut signOut;
  final GetCurrentUser getCurrentUser;
  final CompleteRegistration completeRegistration;
  final CheckRegistrationCompletion checkRegistrationCompletion;

  AuthBloc({
    required this.signIn,
    required this.signUp,
    required this.signOut,
    required this.getCurrentUser,
    required this.completeRegistration,
    required this.checkRegistrationCompletion,
  }) : super(const AuthInitial()) {
    on<SignInEvent>(_onSignIn);
    on<SignUpEvent>(_onSignUp);
    on<SignOutEvent>(_onSignOut);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<CompleteRegistrationEvent>(_onCompleteRegistration);
    on<CheckRegistrationCompletionEvent>(_onCheckRegistrationCompletion);
  }

  Future<void> _onSignIn(SignInEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await signIn(
      SignInParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onSignUp(SignUpEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await signUp(
      SignUpParams(
        email: event.email,
        password: event.password,
        name: event.name,
        phone: event.phone,
        businessName: event.businessName,
        tinNumber: event.tinNumber,
        businessCategory: event.businessCategory,
        registrationNumber: event.registrationNumber,
        programName: event.programName,
        userType: event.userType,
      ),
    );

    result.fold((failure) => emit(AuthError(failure.message)), (user) {
      // After signup, user is created but registration is incomplete
      // They must select universities before accessing the app
      debugPrint('✅ User account created - ID: ${user.id}');
      debugPrint('⏳ Registration incomplete - user must select universities');
      emit(const RegistrationIncomplete());
    });
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await signOut(NoParams());

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const Unauthenticated()),
    );
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await getCurrentUser(NoParams());

    result.fold((failure) => emit(const Unauthenticated()), (user) {
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    });
  }

  Future<void> _onCompleteRegistration(
    CompleteRegistrationEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await completeRegistration(
      CompleteRegistrationParams(
        userId: event.userId,
        primaryUniversityId: event.primaryUniversityId,
        subsidiaryUniversityIds: event.subsidiaryUniversityIds,
      ),
    );

    await result.fold((failure) async => emit(AuthError(failure.message)), (
      _,
    ) async {
      // After completion, reload user
      add(const CheckAuthStatusEvent());
    });
  }

  Future<void> _onCheckRegistrationCompletion(
    CheckRegistrationCompletionEvent event,
    Emitter<AuthState> emit,
  ) async {
    final result = await checkRegistrationCompletion(NoParams());

    result.fold(
      (failure) => null, // Keep current state on failure
      (isComplete) {
        if (!isComplete) {
          emit(const RegistrationIncomplete());
        } else {
          // If complete, we might want to check auth status again or just stay authenticated?
          // Usually we check this after login. If complete, we are Authenticated.
          // If we are already Authenticated, no change needed. But if we were Unauthenticated?
          // This event is usually triggered after login success if we are unsure.
          // But based on _onSignUp logic, we emit RegistrationIncomplete.
          // If isComplete is true, we should probably emit Authenticated(user).
          // But we need the user object.
          // Let's just trigger CheckAuthStatusEvent if complete.
          add(const CheckAuthStatusEvent());
        }
      },
    );
  }
}
