import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/university/domain/usecases/get_selected_university.dart';
import 'package:mwanachuo/features/shared/university/domain/usecases/get_universities.dart';
import 'package:mwanachuo/features/shared/university/domain/usecases/search_universities.dart';
import 'package:mwanachuo/features/shared/university/domain/usecases/set_selected_university.dart';
import 'package:mwanachuo/features/shared/university/presentation/cubit/university_state.dart';

/// Cubit for managing university state
class UniversityCubit extends Cubit<UniversityState> {
  final GetUniversities getUniversities;
  final GetSelectedUniversity getSelectedUniversity;
  final SetSelectedUniversity setSelectedUniversity;
  final SearchUniversities searchUniversities;

  UniversityCubit({
    required this.getUniversities,
    required this.getSelectedUniversity,
    required this.setSelectedUniversity,
    required this.searchUniversities,
  }) : super(UniversityInitial());

  /// Load all universities
  Future<void> loadUniversities() async {
    emit(UniversityLoading());

    final result = await getUniversities(NoParams());
    final selectedResult = await getSelectedUniversity(NoParams());

    result.fold(
      (failure) => emit(UniversityError(message: failure.message)),
      (universities) {
        selectedResult.fold(
          (_) => emit(UniversitiesLoaded(
            universities: universities,
            selectedUniversity: null,
          )),
          (selected) => emit(UniversitiesLoaded(
            universities: universities,
            selectedUniversity: selected,
          )),
        );
      },
    );
  }

  /// Select a university
  Future<void> selectUniversity(String universityId) async {
    emit(UniversityLoading());

    final result = await setSelectedUniversity(
      SetUniversityParams(universityId: universityId),
    );

    result.fold(
      (failure) => emit(UniversityError(message: failure.message)),
      (_) async {
        // Reload universities to update selected state
        await loadUniversities();
      },
    );
  }

  /// Search universities
  Future<void> search(String query) async {
    if (query.isEmpty) {
      await loadUniversities();
      return;
    }

    emit(UniversityLoading());

    final result = await searchUniversities(
      SearchUniversitiesParams(query: query),
    );
    final selectedResult = await getSelectedUniversity(NoParams());

    result.fold(
      (failure) => emit(UniversityError(message: failure.message)),
      (universities) {
        selectedResult.fold(
          (_) => emit(UniversitiesLoaded(
            universities: universities,
            selectedUniversity: null,
          )),
          (selected) => emit(UniversitiesLoaded(
            universities: universities,
            selectedUniversity: selected,
          )),
        );
      },
    );
  }

  /// Get currently selected university
  Future<void> loadSelectedUniversity() async {
    final result = await getSelectedUniversity(NoParams());

    result.fold(
      (failure) => emit(UniversityError(message: failure.message)),
      (university) {
        if (university != null) {
          emit(UniversitySelected(university: university));
        }
      },
    );
  }
}


