import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/university/domain/entities/university_entity.dart';
import 'package:mwanachuo/features/shared/university/domain/repositories/university_repository.dart';

/// Use case for getting all universities
class GetUniversities implements UseCase<List<UniversityEntity>, NoParams> {
  final UniversityRepository repository;

  GetUniversities(this.repository);

  @override
  Future<Either<Failure, List<UniversityEntity>>> call(NoParams params) async {
    return await repository.getUniversities();
  }
}


