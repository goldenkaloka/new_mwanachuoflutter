import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/university/domain/entities/university_entity.dart';
import 'package:mwanachuo/features/shared/university/domain/repositories/university_repository.dart';

/// Use case for searching universities
class SearchUniversities
    implements UseCase<List<UniversityEntity>, SearchUniversitiesParams> {
  final UniversityRepository repository;

  SearchUniversities(this.repository);

  @override
  Future<Either<Failure, List<UniversityEntity>>> call(
    SearchUniversitiesParams params,
  ) async {
    return await repository.searchUniversities(params.query);
  }
}

class SearchUniversitiesParams extends Equatable {
  final String query;

  const SearchUniversitiesParams({required this.query});

  @override
  List<Object?> get props => [query];
}


