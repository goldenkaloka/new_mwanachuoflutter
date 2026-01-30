import 'package:mwanachuo/core/enums/user_role.dart';
import 'package:mwanachuo/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.universityId,
    super.enrolledCourseId,
    super.yearOfStudy,
    super.currentSemester,
    super.profilePicture,
    super.phone,
    required super.createdAt,
    required super.updatedAt,
    super.businessName,
    super.tinNumber,
    super.businessCategory,
    super.registrationNumber,
    super.programName,
    super.userType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['full_name'] as String? ?? json['name'] as String? ?? 'User',
      role: UserRole.fromString(json['role'] as String? ?? 'buyer'),
      universityId: json['primary_university_id'] as String?,
      enrolledCourseId: json['enrolled_course_id'] as String?,
      yearOfStudy: json['year_of_study'] as int?,
      currentSemester: json['current_semester'] as int?,
      profilePicture:
          json['avatar_url'] as String? ?? json['profile_picture'] as String?,
      phone: json['phone_number'] as String? ?? json['phone'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.parse(json['created_at'] as String),
      businessName: json['business_name'] as String?,
      tinNumber: json['tin_number'] as String?,
      businessCategory: json['business_category'] as String?,
      registrationNumber: json['registration_number'] as String?,
      programName: json['program_name'] as String?,
      userType: json['user_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': name,
      'role': role.value,
      'primary_university_id': universityId,
      'enrolled_course_id': enrolledCourseId,
      'year_of_study': yearOfStudy,
      'current_semester': currentSemester,
      'avatar_url': profilePicture,
      'phone_number': phone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'business_name': businessName,
      'tin_number': tinNumber,
      'business_category': businessCategory,
      'registration_number': registrationNumber,
      'program_name': programName,
      'user_type': userType,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? universityId,
    String? enrolledCourseId,
    int? yearOfStudy,
    int? currentSemester,
    String? profilePicture,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? businessName,
    String? tinNumber,
    String? businessCategory,
    String? registrationNumber,
    String? programName,
    String? userType,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      universityId: universityId ?? this.universityId,
      enrolledCourseId: enrolledCourseId ?? this.enrolledCourseId,
      yearOfStudy: yearOfStudy ?? this.yearOfStudy,
      currentSemester: currentSemester ?? this.currentSemester,
      profilePicture: profilePicture ?? this.profilePicture,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      businessName: businessName ?? this.businessName,
      tinNumber: tinNumber ?? this.tinNumber,
      businessCategory: businessCategory ?? this.businessCategory,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      programName: programName ?? this.programName,
      userType: userType ?? this.userType,
    );
  }
}
