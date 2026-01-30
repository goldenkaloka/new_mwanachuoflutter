import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  /// Sign in with email and password
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  });

  /// Sign up with email, password, and name
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    String? businessName,
    String? tinNumber,
    String? businessCategory,
    String? registrationNumber,
    String? programName,
    String? userType,
    String? universityId,
    String? enrolledCourseId,
    int? yearOfStudy,
    int? currentSemester,
  });

  /// Sign out current user
  Future<Either<Failure, void>> signOut();

  /// Get current user
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Check if user is logged in
  Future<Either<Failure, bool>> isLoggedIn();

  /// Update user profile
  Future<Either<Failure, UserEntity>> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? profilePicture,
  });

  /// Complete registration with university selection
  Future<Either<Failure, void>> completeRegistration({
    required String userId,
    required String primaryUniversityId,
    required List<String> subsidiaryUniversityIds,
  });

  /// Check if current user has completed registration
  Future<Either<Failure, bool>> checkRegistrationCompletion();

  /// Stream auth state changes
  Stream<Either<Failure, UserEntity?>> watchAuthState();

  /// Reset password for email
  Future<Either<Failure, void>> resetPassword(String email);
}
