import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class SignInEvent extends AuthEvent {
  final String email;
  final String password;

  const SignInEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class SignUpEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const SignUpEvent({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object> get props => [email, password, name];
}

class SignOutEvent extends AuthEvent {
  const SignOutEvent();
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

class RequestSellerAccessEvent extends AuthEvent {
  final String userId;
  final String reason;

  const RequestSellerAccessEvent({
    required this.userId,
    required this.reason,
  });

  @override
  List<Object> get props => [userId, reason];
}

class UpdateProfileEvent extends AuthEvent {
  final String userId;
  final String? name;
  final String? phone;
  final String? profilePicture;

  const UpdateProfileEvent({
    required this.userId,
    this.name,
    this.phone,
    this.profilePicture,
  });

  @override
  List<Object?> get props => [userId, name, phone, profilePicture];
}

class CompleteRegistrationEvent extends AuthEvent {
  final String userId;
  final String primaryUniversityId;
  final List<String> subsidiaryUniversityIds;

  const CompleteRegistrationEvent({
    required this.userId,
    required this.primaryUniversityId,
    required this.subsidiaryUniversityIds,
  });

  @override
  List<Object> get props => [userId, primaryUniversityId, subsidiaryUniversityIds];
}

class CheckRegistrationCompletionEvent extends AuthEvent {
  const CheckRegistrationCompletionEvent();
}

class GetSellerRequestStatusEvent extends AuthEvent {
  const GetSellerRequestStatusEvent();
}

class ApproveSellerRequestEvent extends AuthEvent {
  final String requestId;
  final String adminId;
  final String? notes;

  const ApproveSellerRequestEvent({
    required this.requestId,
    required this.adminId,
    this.notes,
  });

  @override
  List<Object?> get props => [requestId, adminId, notes];
}

class RejectSellerRequestEvent extends AuthEvent {
  final String requestId;
  final String adminId;
  final String? notes;

  const RejectSellerRequestEvent({
    required this.requestId,
    required this.adminId,
    this.notes,
  });

  @override
  List<Object?> get props => [requestId, adminId, notes];
}

class LoadSellerRequestsEvent extends AuthEvent {
  final String? status; // pending, approved, rejected, or null for all

  const LoadSellerRequestsEvent({this.status});

  @override
  List<Object?> get props => [status];
}

