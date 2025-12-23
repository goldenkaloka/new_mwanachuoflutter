import '../repositories/mwanachuomind_repository.dart';

class CreateCourseUseCase {
  final MwanachuomindRepository repository;

  CreateCourseUseCase(this.repository);

  Future<void> call({
    required String code,
    required String name,
    required String universityId,
  }) async {
    return await repository.createCourse(
      code: code,
      name: name,
      universityId: universityId,
    );
  }
}
