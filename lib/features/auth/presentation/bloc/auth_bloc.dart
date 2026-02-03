import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/auth/domain/usecases/check_registration_completion.dart';
import 'package:mwanachuo/features/auth/domain/usecases/complete_registration.dart';
import 'package:mwanachuo/features/auth/domain/usecases/get_current_user.dart';

import 'package:mwanachuo/features/auth/domain/usecases/sign_in.dart';
import 'package:mwanachuo/features/auth/domain/usecases/sign_out.dart';
import 'package:mwanachuo/features/auth/domain/usecases/sign_up.dart';
import 'package:mwanachuo/features/auth/domain/usecases/reset_password.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignIn signIn;
  final SignUp signUp;
  final SignOut signOut;
  final GetCurrentUser getCurrentUser;
  final CompleteRegistration completeRegistration;
  final CheckRegistrationCompletion checkRegistrationCompletion;
  final ResetPassword resetPassword;

  AuthBloc({
    required this.signIn,
    required this.signUp,
    required this.signOut,
    required this.getCurrentUser,
    required this.completeRegistration,
    required this.checkRegistrationCompletion,
    required this.resetPassword,
  }) : super(const AuthInitial()) {
    on<SignInEvent>(_onSignIn);
    on<SignUpEvent>(_onSignUp);
    on<SignOutEvent>(_onSignOut);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<CompleteRegistrationEvent>(_onCompleteRegistration);
    on<CheckRegistrationCompletionEvent>(_onCheckRegistrationCompletion);
    on<ResetPasswordEvent>(_onResetPassword);
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
        programName: event.programName,
        userType: event.userType,
        universityId: event.universityId,
        enrolledCourseId: event.enrolledCourseId,
        yearOfStudy: event.yearOfStudy,
        currentSemester: event.currentSemester,
      ),
    );

    result.fold((failure) => emit(AuthError(failure.message)), (user) {
      // Registration is now complete with all required fields
      debugPrint('✅ User account created - ID: ${user.id}');
      debugPrint('✅ Registration complete - redirecting to home');
      emit(Authenticated(user));
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

    result.fold((failure) => emit(AuthError(failure.message)), (isComplete) {
      if (!isComplete) {
        emit(const RegistrationIncomplete());
      } else {
        emit(const RegistrationCheckCompleted(true));
      }
    });
  }

  Future<void> _onResetPassword(
    ResetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await resetPassword(ResetPasswordParams(email: event.email));

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const PasswordResetSent()),
    );
  }
}
