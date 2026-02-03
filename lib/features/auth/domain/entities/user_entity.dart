import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/enums/user_role.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? universityId;
  final String? enrolledCourseId;
  final int? yearOfStudy; // 1-7
  final int? currentSemester; // 1 or 2
  final String? profilePicture;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int freeListingsCount;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.universityId,
    this.enrolledCourseId,
    this.yearOfStudy,
    this.currentSemester,
    this.profilePicture,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
    this.freeListingsCount = 0,
    this.businessName,
    this.tinNumber,
    this.businessCategory,
    this.programName,
    this.userType,
  });

  final String? businessName;
  final String? tinNumber;
  final String? businessCategory;
  final String? programName;
  final String? userType;

  bool get isBuyer => role == UserRole.buyer;
  bool get isSeller => role == UserRole.seller || role == UserRole.admin;
  bool get isAdmin => role == UserRole.admin;

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    role,
    universityId,
    enrolledCourseId,
    yearOfStudy,
    currentSemester,
    profilePicture,
    phone,
    createdAt,
    createdAt,
    updatedAt,
    businessName,
    tinNumber,
    businessCategory,
    programName,
    userType,
    freeListingsCount,
  ];
}
