import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/university/domain/entities/university_entity.dart';
import 'package:mwanachuo/features/shared/university/domain/repositories/university_repository.dart';

/// Use case for getting the currently selected university
class GetSelectedUniversity
    implements UseCase<UniversityEntity?, NoParams> {
  final UniversityRepository repository;

  GetSelectedUniversity(this.repository);

  @override
  Future<Either<Failure, UniversityEntity?>> call(NoParams params) async {
    return await repository.getSelectedUniversity();
  }
}


