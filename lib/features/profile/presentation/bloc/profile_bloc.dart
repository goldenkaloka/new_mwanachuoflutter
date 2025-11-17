import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/profile/domain/usecases/get_my_profile.dart';
import 'package:mwanachuo/features/profile/domain/usecases/update_profile.dart';
import 'package:mwanachuo/features/profile/presentation/bloc/profile_event.dart';
import 'package:mwanachuo/features/profile/presentation/bloc/profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetMyProfile getMyProfile;
  final UpdateProfile updateProfile;

  ProfileBloc({
    required this.getMyProfile,
    required this.updateProfile,
  }) : super(ProfileInitial()) {
    on<LoadMyProfileEvent>(_onLoadMyProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
  }

  Future<void> _onLoadMyProfile(
    LoadMyProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    final result = await getMyProfile(NoParams());

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (profile) => emit(ProfileLoaded(profile: profile)),
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileUpdating());

    final result = await updateProfile(
      UpdateProfileParams(
        fullName: event.fullName,
        phoneNumber: event.phoneNumber,
        bio: event.bio,
        location: event.location,
        avatarImage: event.avatarImage,
      ),
    );

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (profile) => emit(ProfileUpdated(profile: profile)),
    );
  }
}

