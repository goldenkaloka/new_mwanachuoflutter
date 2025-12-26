import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadMyProfileEvent extends ProfileEvent {}

class LoadUserProfileEvent extends ProfileEvent {
  final String userId;

  const LoadUserProfileEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class UpdateProfileEvent extends ProfileEvent {
  final String? fullName;
  final String? phoneNumber;
  final String? bio;
  final String? location;
  final File? avatarImage;
  final String? primaryUniversityId;
  final String? universityName;

  const UpdateProfileEvent({
    this.fullName,
    this.phoneNumber,
    this.bio,
    this.location,
    this.avatarImage,
    this.primaryUniversityId,
    this.universityName,
  });

  @override
  List<Object?> get props => [
    fullName,
    phoneNumber,
    bio,
    location,
    avatarImage,
    primaryUniversityId,
    universityName,
  ];
}
