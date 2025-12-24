import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/auth/domain/usecases/approve_seller_request.dart';
import 'package:mwanachuo/features/auth/domain/usecases/check_registration_completion.dart';
import 'package:mwanachuo/features/auth/domain/usecases/complete_registration.dart';
import 'package:mwanachuo/features/auth/domain/usecases/get_current_user.dart';
import 'package:mwanachuo/features/auth/domain/usecases/get_seller_request_status.dart';
import 'package:mwanachuo/features/auth/domain/usecases/get_seller_requests.dart';
import 'package:mwanachuo/features/auth/domain/usecases/reject_seller_request.dart';
import 'package:mwanachuo/features/auth/domain/usecases/request_seller_access.dart';
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
  final RequestSellerAccess requestSellerAccess;
  final ApproveSellerRequest approveSellerRequest;
  final RejectSellerRequest rejectSellerRequest;
  final GetSellerRequests getSellerRequests;
  final CompleteRegistration completeRegistration;
  final CheckRegistrationCompletion checkRegistrationCompletion;
  final GetSellerRequestStatus getSellerRequestStatus;

  AuthBloc({
    required this.signIn,
    required this.signUp,
    required this.signOut,
    required this.getCurrentUser,
    required this.requestSellerAccess,
    required this.approveSellerRequest,
    required this.rejectSellerRequest,
    required this.getSellerRequests,
    required this.completeRegistration,
    required this.checkRegistrationCompletion,
    required this.getSellerRequestStatus,
  }) : super(const AuthInitial()) {
    on<SignInEvent>(_onSignIn);
    on<SignUpEvent>(_onSignUp);
    on<SignOutEvent>(_onSignOut);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<RequestSellerAccessEvent>(_onRequestSellerAccess);
    on<ApproveSellerRequestEvent>(_onApproveSellerRequest);
    on<RejectSellerRequestEvent>(_onRejectSellerRequest);
    on<LoadSellerRequestsEvent>(_onLoadSellerRequests);
    on<CompleteRegistrationEvent>(_onCompleteRegistration);
    on<CheckRegistrationCompletionEvent>(_onCheckRegistrationCompletion);
    on<GetSellerRequestStatusEvent>(_onGetSellerRequestStatus);
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

  Future<void> _onRequestSellerAccess(
    RequestSellerAccessEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await requestSellerAccess(
      RequestSellerAccessParams(userId: event.userId, reason: event.reason),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const SellerRequestSubmitted()),
    );
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
      debugPrint('✅ Registration completed with universities');

      // Emit temporary state
      emit(const RegistrationCompleted());

      // Get updated user data with universities
      final userResult = await getCurrentUser(NoParams());
      userResult.fold(
        (failure) => emit(
          AuthError(
            'Registration completed but failed to load user: ${failure.message}',
          ),
        ),
        (user) {
          if (user != null) {
            debugPrint(
              '✅ User authenticated with universities - ID: ${user.id}',
            );
            emit(Authenticated(user));
          } else {
            emit(const Unauthenticated());
          }
        },
      );
    });
  }

  Future<void> _onCheckRegistrationCompletion(
    CheckRegistrationCompletionEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await checkRegistrationCompletion(NoParams());

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (isCompleted) => emit(RegistrationCheckCompleted(isCompleted)),
    );
  }

  Future<void> _onGetSellerRequestStatus(
    GetSellerRequestStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await getSellerRequestStatus(NoParams());

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (status) => emit(SellerRequestStatusLoaded(status)),
    );
  }

  Future<void> _onApproveSellerRequest(
    ApproveSellerRequestEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await approveSellerRequest(
      ApproveSellerRequestParams(
        requestId: event.requestId,
        adminId: event.adminId,
        notes: event.notes,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const SellerRequestApproved()),
    );
  }

  Future<void> _onRejectSellerRequest(
    RejectSellerRequestEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await rejectSellerRequest(
      RejectSellerRequestParams(
        requestId: event.requestId,
        adminId: event.adminId,
        notes: event.notes,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const SellerRequestRejected()),
    );
  }

  Future<void> _onLoadSellerRequests(
    LoadSellerRequestsEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const SellerRequestsLoading());

    final result = await getSellerRequests(
      GetSellerRequestsParams(status: event.status),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (requests) => emit(SellerRequestsLoaded(requests: requests)),
    );
  }
}
