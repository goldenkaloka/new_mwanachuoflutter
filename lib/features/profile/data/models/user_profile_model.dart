import 'package:mwanachuo/core/enums/user_role.dart';
import 'package:mwanachuo/features/profile/domain/entities/user_profile_entity.dart';

class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.id,
    required super.fullName,
    required super.email,
    super.phoneNumber,
    super.avatarUrl,
    required super.role,
    super.universityId,
    super.universityName,
    super.bio,
    super.location,
    required super.createdAt,
    super.updatedAt,
    super.productCount,
    super.serviceCount,
    super.accommodationCount,
    super.averageRating,
    super.totalReviews,
    super.yearOfStudy,
    super.currentSemester,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: UserRole.values.firstWhere(
        (r) => r.toString().split('.').last == (json['role'] as String),
        orElse: () => UserRole.buyer,
      ),
      universityId: json['primary_university_id'] as String?,
      universityName: json['university_name'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      productCount: json['product_count'] as int? ?? 0,
      serviceCount: json['service_count'] as int? ?? 0,
      accommodationCount: json['accommodation_count'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      totalReviews: json['total_reviews'] as int? ?? 0,
      yearOfStudy: json['year_of_study'] as int?,
      currentSemester: json['current_semester'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'role': role.toString().split('.').last,
      'primary_university_id': universityId,
      'university_name': universityName,
      'bio': bio,
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'product_count': productCount,
      'service_count': serviceCount,
      'accommodation_count': accommodationCount,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'year_of_study': yearOfStudy,
      'current_semester': currentSemester,
    };
  }
}
