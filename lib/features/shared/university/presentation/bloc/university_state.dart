import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/shared/university/domain/entities/university_entity.dart';
import 'package:mwanachuo/features/shared/university/domain/entities/course_entity.dart';

abstract class UniversityState extends Equatable {
  const UniversityState();

  @override
  List<Object?> get props => [];
}

class UniversityInitial extends UniversityState {}

class UniversityLoading extends UniversityState {}

class UniversitiesLoaded extends UniversityState {
  final List<UniversityEntity> universities;

  const UniversitiesLoaded(this.universities);

  @override
  List<Object?> get props => [universities];
}

class UniversityCoursesLoading extends UniversityState {}

class UniversityCoursesLoaded extends UniversityState {
  final List<CourseEntity> courses;

  const UniversityCoursesLoaded(this.courses);

  @override
  List<Object?> get props => [courses];
}

class UniversityError extends UniversityState {
  final String message;

  const UniversityError(this.message);

  @override
  List<Object?> get props => [message];
}
