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
import 'package:mwanachuo/features/profile/domain/repositories/profile_repository.dart';
import 'package:mwanachuo/features/shared/media/domain/usecases/upload_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final ProfileLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final UploadImage uploadImage;
  final SharedPreferences sharedPreferences;

  ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.uploadImage,
    required this.sharedPreferences,
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
    // Try cache first if not expired
    if (!localDataSource.isProfileCacheExpired()) {
      try {
        debugPrint('💾 Loading my profile from cache');
        final cachedProfile = await localDataSource.getCachedMyProfile();
        return Right(cachedProfile);
      } on CacheException {
        debugPrint('❌ Cache miss for profile, fetching from server');
      }
    }

    // Check network
    if (!await networkInfo.isConnected) {
      // Try to return cached data even if expired
      try {
        final cachedProfile = await localDataSource.getCachedMyProfile();
        return Right(cachedProfile);
      } on CacheException {
        return Left(NetworkFailure('No internet connection and no cached profile'));
      }
    }

    // Fetch from server
    try {
      debugPrint('🌐 Fetching my profile from server');
      final profile = await remoteDataSource.getMyProfile();
      
      // Cache the result
      await localDataSource.cacheMyProfile(profile);
      debugPrint('✅ Profile cached successfully');
      
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
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      String? avatarUrl;

      // Upload avatar if provided
      if (avatarImage != null) {
        final uploadResult = await uploadImage(
          UploadImageParams(
            imageFile: avatarImage,
            bucket: DatabaseConstants.profileImagesBucket,
            folder: 'avatars',
          ),
        );

        avatarUrl = uploadResult.fold(
          (failure) => null,
          (media) => media.url,
        );
      }

      final profile = await remoteDataSource.updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        bio: bio,
        location: location,
        avatarUrl: avatarUrl,
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
      (result) => result.fold(
        (failure) => Left(failure),
        (_) => const Right(null),
      ),
    );
  }

  @override
  Future<Either<Failure, void>> deleteAvatar() async {
    return await updateProfile(avatarImage: null).then(
      (result) => result.fold(
        (failure) => Left(failure),
        (_) => const Right(null),
      ),
    );
  }
}

