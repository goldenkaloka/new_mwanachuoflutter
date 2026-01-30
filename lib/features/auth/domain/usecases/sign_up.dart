import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/auth/domain/entities/user_entity.dart';
import 'package:mwanachuo/features/auth/domain/repositories/auth_repository.dart';

class SignUp implements UseCase<UserEntity, SignUpParams> {
  final AuthRepository repository;

  SignUp(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) async {
    return await repository.signUp(
      email: params.email,
      password: params.password,
      name: params.name,
      phone: params.phone,
      businessName: params.businessName,
      tinNumber: params.tinNumber,
      businessCategory: params.businessCategory,
      registrationNumber: params.registrationNumber,
      programName: params.programName,
      userType: params.userType,
      universityId: params.universityId,
      enrolledCourseId: params.enrolledCourseId,
      yearOfStudy: params.yearOfStudy,
      currentSemester: params.currentSemester,
    );
  }
}

class SignUpParams extends Equatable {
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
  final String? universityId;
  final String? enrolledCourseId;
  final int? yearOfStudy;
  final int? currentSemester;

  const SignUpParams({
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
    this.universityId,
    this.enrolledCourseId,
    this.yearOfStudy,
    this.currentSemester,
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
    universityId,
    enrolledCourseId,
    yearOfStudy,
    currentSemester,
  ];
}
