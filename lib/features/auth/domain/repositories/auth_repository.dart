import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/auth/domain/entities/seller_request_entity.dart';
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
  });

  /// Sign out current user
  Future<Either<Failure, void>> signOut();

  /// Get current user
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Check if user is logged in
  Future<Either<Failure, bool>> isLoggedIn();

  /// Request seller access
  Future<Either<Failure, void>> requestSellerAccess({
    required String userId,
    required String reason,
  });

  /// Approve seller request (Admin only)
  Future<Either<Failure, void>> approveSellerRequest({
    required String requestId,
    required String adminId,
    String? notes,
  });

  /// Reject seller request (Admin only)
  Future<Either<Failure, void>> rejectSellerRequest({
    required String requestId,
    required String adminId,
    String? notes,
  });

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

  /// Get seller request status for current user
  Future<Either<Failure, String?>> getSellerRequestStatus();

  /// Get all seller requests (Admin only)
  Future<Either<Failure, List<SellerRequestEntity>>> getSellerRequests({
    String? status, // pending, approved, rejected, or null for all
  });

  /// Get seller request by ID (Admin only)
  Future<Either<Failure, SellerRequestEntity>> getSellerRequestById(
    String requestId,
  );

  /// Stream auth state changes
  Stream<Either<Failure, UserEntity?>> watchAuthState();
}
