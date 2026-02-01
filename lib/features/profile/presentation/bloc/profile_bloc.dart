import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/profile/domain/usecases/get_my_profile.dart';
import 'package:mwanachuo/features/profile/domain/usecases/update_profile.dart';
import 'package:mwanachuo/features/profile/domain/usecases/get_enrolled_course.dart';
import 'package:mwanachuo/features/profile/domain/usecases/enroll_in_course.dart';
import 'package:mwanachuo/features/profile/presentation/bloc/profile_event.dart';
import 'package:mwanachuo/features/profile/presentation/bloc/profile_state.dart';
import 'package:mwanachuo/core/services/university_service.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetMyProfile getMyProfile;
  final UpdateProfile updateProfile;
  final GetEnrolledCourse getEnrolledCourse;
  final EnrollInCourse enrollInCourse;

  ProfileBloc({
    required this.getMyProfile,
    required this.updateProfile,
    required this.getEnrolledCourse,
    required this.enrollInCourse,
  }) : super(ProfileInitial()) {
    on<LoadMyProfileEvent>(_onLoadMyProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<LoadEnrolledCourse>(_onLoadEnrolledCourse);
    on<EnrollUserInCourse>(_onEnrollUserInCourse);
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
        primaryUniversityId: event.primaryUniversityId,
        yearOfStudy: event.yearOfStudy,
        currentSemester: event.currentSemester,
      ),
    );

    await result.fold(
      (failure) async => emit(ProfileError(message: failure.message)),
      (profile) async {
        if (event.universityName != null) {
          await UniversityService.saveSelectedUniversity(event.universityName!);
        }
        emit(ProfileUpdated(profile: profile));
      },
    );
  }

  Future<void> _onLoadEnrolledCourse(
    LoadEnrolledCourse event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await getEnrolledCourse(event.userId);
    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (course) => emit(ProfileEnrolledCourseLoaded(course: course)),
    );
  }

  Future<void> _onEnrollUserInCourse(
    EnrollUserInCourse event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await enrollInCourse(
      userId: event.userId,
      courseId: event.courseId,
    );
    result.fold((failure) => emit(ProfileError(message: failure.message)), (_) {
      // After successful enrollment, reload to get the course details
      add(LoadEnrolledCourse(userId: event.userId));
    });
  }
}
