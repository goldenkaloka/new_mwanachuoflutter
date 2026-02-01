import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/network/network_info.dart';
import 'package:mwanachuo/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:mwanachuo/features/profile/data/datasources/profile_local_data_source.dart';
import 'package:mwanachuo/features/profile/domain/entities/user_profile_entity.dart';
import 'package:mwanachuo/features/shared/university/domain/entities/course_entity.dart';
import 'package:mwanachuo/features/profile/domain/repositories/profile_repository.dart';
import 'package:mwanachuo/features/shared/media/domain/usecases/upload_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final ProfileLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final UploadImage uploadImage;
  final SharedPreferences sharedPreferences;
  final SupabaseClient supabaseClient;

  ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.uploadImage,
    required this.sharedPreferences,
    required this.supabaseClient,
  });

  @override
  Future<Either<Failure, UserProfileEntity>> getUserProfile(
    String userId,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final profile = await remoteDataSource.getUserProfile(userId);
      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get user profile: $e'));
    }
  }

  @override
  Future<Either<Failure, UserProfileEntity>> getMyProfile() async {
    // Get current user ID to validate cache
    final currentUser = supabaseClient.auth.currentUser;
    if (currentUser == null) {
      // Clear cache if no user is authenticated
      await localDataSource.clearCache();
      return Left(ServerFailure('User not authenticated'));
    }

    final currentUserId = currentUser.id;

    // Try cache first if not expired
    if (!localDataSource.isProfileCacheExpired()) {
      try {
        debugPrint('💾 Loading my profile from cache');
        final cachedProfile = await localDataSource.getCachedMyProfile();

        // Validate that cached profile belongs to current user
        if (cachedProfile.id != currentUserId) {
          debugPrint(
            '⚠️ Cached profile belongs to different user (${cachedProfile.id} vs $currentUserId), clearing cache',
          );
          await localDataSource.clearCache();
          // Fall through to fetch from server
        } else {
          debugPrint('✅ Cached profile validated for current user');
          return Right(cachedProfile);
        }
      } on CacheException {
        debugPrint('❌ Cache miss for profile, fetching from server');
      }
    }

    // Check network
    if (!await networkInfo.isConnected) {
      // Try to return cached data even if expired, but validate user ID
      try {
        final cachedProfile = await localDataSource.getCachedMyProfile();
        if (cachedProfile.id == currentUserId) {
          return Right(cachedProfile);
        } else {
          await localDataSource.clearCache();
          return Left(
            NetworkFailure(
              'No internet connection and cached profile belongs to different user',
            ),
          );
        }
      } on CacheException {
        return Left(
          NetworkFailure('No internet connection and no cached profile'),
        );
      }
    }

    // Fetch from server
    try {
      debugPrint('🌐 Fetching my profile from server for user: $currentUserId');
      final profile = await remoteDataSource.getMyProfile();

      // Validate the fetched profile belongs to current user
      if (profile.id != currentUserId) {
        debugPrint(
          '❌ Fetched profile ID (${profile.id}) does not match current user ID ($currentUserId)',
        );
        return Left(ServerFailure('Profile ID mismatch'));
      }

      // Cache the result
      await localDataSource.cacheMyProfile(profile);
      debugPrint('✅ Profile cached successfully for user: $currentUserId');

      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get my profile: $e'));
    }
  }

  @override
  Future<Either<Failure, UserProfileEntity>> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? bio,
    String? location,
    File? avatarImage,
    String? primaryUniversityId,
    int? yearOfStudy,
    int? currentSemester,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      String? avatarUrl;

      // Upload avatar if provided
      if (avatarImage != null) {
        // Get current user ID for folder structure (RLS policy requires user_id as first folder)
        final currentUser = supabaseClient.auth.currentUser;
        if (currentUser == null) {
          return Left(ServerFailure('User not authenticated'));
        }

        final uploadResult = await uploadImage(
          UploadImageParams(
            imageFile: avatarImage,
            bucket: DatabaseConstants.profileImagesBucket,
            folder: currentUser.id, // Use user ID as folder to match RLS policy
          ),
        );

        avatarUrl = uploadResult.fold((failure) => null, (media) => media.url);
      }

      final profile = await remoteDataSource.updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        bio: bio,
        location: location,
        avatarUrl: avatarUrl,
        primaryUniversityId: primaryUniversityId,
        yearOfStudy: yearOfStudy,
        currentSemester: currentSemester,
      );

      // Update cache after successful update
      debugPrint('🔄 Updating cached profile after update');
      await localDataSource.cacheMyProfile(profile);

      return Right(profile);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to update profile: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateAvatar(File avatarImage) async {
    return await updateProfile(avatarImage: avatarImage).then(
      (result) =>
          result.fold((failure) => Left(failure), (_) => const Right(null)),
    );
  }

  @override
  Future<Either<Failure, void>> deleteAvatar() async {
    return await updateProfile(avatarImage: null).then(
      (result) =>
          result.fold((failure) => Left(failure), (_) => const Right(null)),
    );
  }

  @override
  Future<Either<Failure, CourseEntity?>> getEnrolledCourse(
    String userId,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }
    try {
      final userData = await supabaseClient
          .from('users')
          .select('enrolled_course_id')
          .eq('id', userId)
          .single();

      final courseId = userData['enrolled_course_id'] as String?;
      if (courseId == null) return const Right(null);

      final courseData = await supabaseClient
          .from('courses')
          .select()
          .eq('id', courseId)
          .single();

      // We use CourseModel from shared/university to parse the data
      // For now, return a basic CourseEntity since we haven't imported CourseModel here yet
      // A better approach is to add getEnrolledCourse to RemoteDataSource, but keeping it simple for migration
      return Right(
        CourseEntity(
          id: courseData['id'] as String,
          universityId: courseData['university_id'] as String,
          name: courseData['name'] as String,
          code: courseData['code'] as String,
          description: courseData['description'] as String?,
          createdAt: DateTime.parse(courseData['created_at'] as String),
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setEnrolledCourse(
    String userId,
    String? courseId,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }
    try {
      await supabaseClient
          .from('users')
          .update({'enrolled_course_id': courseId})
          .eq('id', userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
