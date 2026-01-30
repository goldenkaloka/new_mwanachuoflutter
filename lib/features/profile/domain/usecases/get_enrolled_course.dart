import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/shared/university/domain/entities/course_entity.dart';
import 'package:mwanachuo/features/profile/domain/repositories/profile_repository.dart';

class GetEnrolledCourse {
  final ProfileRepository repository;

  GetEnrolledCourse(this.repository);

  Future<Either<Failure, CourseEntity?>> call(String userId) async {
    return await repository.getEnrolledCourse(userId);
  }
}
