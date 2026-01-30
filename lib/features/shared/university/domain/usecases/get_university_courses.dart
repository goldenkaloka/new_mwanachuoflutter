import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/shared/university/domain/entities/course_entity.dart';
import 'package:mwanachuo/features/shared/university/domain/repositories/university_repository.dart';

class GetUniversityCourses {
  final UniversityRepository repository;

  GetUniversityCourses(this.repository);

  Future<Either<Failure, List<CourseEntity>>> call(String universityId) async {
    return await repository.getUniversityCourses(universityId);
  }
}
