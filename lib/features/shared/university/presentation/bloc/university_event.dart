import 'package:equatable/equatable.dart';

abstract class UniversityEvent extends Equatable {
  const UniversityEvent();

  @override
  List<Object?> get props => [];
}

class LoadUniversities extends UniversityEvent {
  const LoadUniversities();
}

class LoadUniversityCourses extends UniversityEvent {
  final String universityId;

  const LoadUniversityCourses(this.universityId);

  @override
  List<Object?> get props => [universityId];
}

class SearchUniversities extends UniversityEvent {
  final String query;

  const SearchUniversities(this.query);

  @override
  List<Object?> get props => [query];
}
