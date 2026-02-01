import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/enums/user_role.dart';

/// User profile entity
class UserProfileEntity extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final UserRole role;
  final String? universityId;
  final String? universityName;
  final String? bio;
  final String? location;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int productCount;
  final int serviceCount;
  final int accommodationCount;
  final double? averageRating;
  final int totalReviews;
  final int? yearOfStudy;
  final int? currentSemester;

  const UserProfileEntity({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    required this.role,
    this.universityId,
    this.universityName,
    this.bio,
    this.location,
    required this.createdAt,
    this.updatedAt,
    this.productCount = 0,
    this.serviceCount = 0,
    this.accommodationCount = 0,
    this.averageRating,
    this.totalReviews = 0,
    this.yearOfStudy,
    this.currentSemester,
  });

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    phoneNumber,
    avatarUrl,
    role,
    universityId,
    universityName,
    bio,
    location,
    createdAt,
    updatedAt,
    productCount,
    serviceCount,
    accommodationCount,
    averageRating,
    totalReviews,
    yearOfStudy,
    currentSemester,
  ];
}
