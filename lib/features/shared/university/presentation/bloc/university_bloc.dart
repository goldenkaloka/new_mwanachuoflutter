import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/shared/university/domain/repositories/university_repository.dart';
import 'package:mwanachuo/features/shared/university/domain/usecases/get_university_courses.dart';
import 'university_event.dart';
import 'university_state.dart';

class UniversityBloc extends Bloc<UniversityEvent, UniversityState> {
  final UniversityRepository repository;
  final GetUniversityCourses getUniversityCourses;

  UniversityBloc({required this.repository, required this.getUniversityCourses})
    : super(UniversityInitial()) {
    on<LoadUniversities>(_onLoadUniversities);
    on<LoadUniversityCourses>(_onLoadUniversityCourses);
    on<SearchUniversities>(_onSearchUniversities);
  }

  Future<void> _onLoadUniversities(
    LoadUniversities event,
    Emitter<UniversityState> emit,
  ) async {
    emit(UniversityLoading());
    final result = await repository.getUniversities();
    result.fold(
      (failure) => emit(UniversityError(failure.message)),
      (universities) => emit(UniversitiesLoaded(universities)),
    );
  }

  Future<void> _onLoadUniversityCourses(
    LoadUniversityCourses event,
    Emitter<UniversityState> emit,
  ) async {
    emit(UniversityCoursesLoading());
    final result = await getUniversityCourses(event.universityId);
    result.fold(
      (failure) => emit(UniversityError(failure.message)),
      (courses) => emit(UniversityCoursesLoaded(courses)),
    );
  }

  Future<void> _onSearchUniversities(
    SearchUniversities event,
    Emitter<UniversityState> emit,
  ) async {
    emit(UniversityLoading());
    final result = await repository.searchUniversities(event.query);
    result.fold(
      (failure) => emit(UniversityError(failure.message)),
      (universities) => emit(UniversitiesLoaded(universities)),
    );
  }
}
