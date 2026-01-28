import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class SignInEvent extends AuthEvent {
  final String email;
  final String password;

  const SignInEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class SignUpEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String phone;
  final String? businessName;
  final String? tinNumber;
  final String? businessCategory;
  final String? registrationNumber;
  final String? programName;
  final String? userType;

  const SignUpEvent({
    required this.email,
    required this.password,
    required this.name,
    required this.phone,
    this.businessName,
    this.tinNumber,
    this.businessCategory,
    this.registrationNumber,
    this.programName,
    this.userType,
  });

  @override
  List<Object?> get props => [
    email,
    password,
    name,
    phone,
    businessName,
    tinNumber,
    businessCategory,
    registrationNumber,
    programName,
    userType,
  ];
}

class SignOutEvent extends AuthEvent {
  const SignOutEvent();
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
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
  List<Object> get props => [
    userId,
    primaryUniversityId,
    subsidiaryUniversityIds,
  ];
}

class CheckRegistrationCompletionEvent extends AuthEvent {
  const CheckRegistrationCompletionEvent();
}
