import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/profile/domain/repositories/profile_repository.dart';

class EnrollInCourse {
  final ProfileRepository repository;

  EnrollInCourse(this.repository);

  Future<Either<Failure, void>> call({
    required String userId,
    required String courseId,
  }) async {
    return await repository.setEnrolledCourse(userId, courseId);
  }
}
