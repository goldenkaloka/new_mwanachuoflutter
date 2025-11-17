import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/profile/domain/entities/user_profile_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserProfileEntity>> getUserProfile(String userId);
  Future<Either<Failure, UserProfileEntity>> getMyProfile();
  Future<Either<Failure, UserProfileEntity>> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? bio,
    String? location,
    File? avatarImage,
  });
  Future<Either<Failure, void>> updateAvatar(File avatarImage);
  Future<Either<Failure, void>> deleteAvatar();
}

