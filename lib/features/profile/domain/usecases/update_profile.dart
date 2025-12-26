import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/profile/domain/entities/user_profile_entity.dart';
import 'package:mwanachuo/features/profile/domain/repositories/profile_repository.dart';

class UpdateProfile implements UseCase<UserProfileEntity, UpdateProfileParams> {
  final ProfileRepository repository;

  UpdateProfile(this.repository);

  @override
  Future<Either<Failure, UserProfileEntity>> call(
    UpdateProfileParams params,
  ) async {
    return await repository.updateProfile(
      fullName: params.fullName,
      phoneNumber: params.phoneNumber,
      bio: params.bio,
      location: params.location,
      avatarImage: params.avatarImage,
      primaryUniversityId: params.primaryUniversityId,
    );
  }
}

class UpdateProfileParams extends Equatable {
  final String? fullName;
  final String? phoneNumber;
  final String? bio;
  final String? location;
  final File? avatarImage;
  final String? primaryUniversityId;

  const UpdateProfileParams({
    this.fullName,
    this.phoneNumber,
    this.bio,
    this.location,
    this.avatarImage,
    this.primaryUniversityId,
  });

  @override
  List<Object?> get props => [
    fullName,
    phoneNumber,
    bio,
    location,
    avatarImage,
    primaryUniversityId,
  ];
}
