import '../entities/course.dart';
import '../repositories/mwanachuomind_repository.dart';

class GetUniversityCoursesUseCase {
  final MwanachuomindRepository repository;

  GetUniversityCoursesUseCase(this.repository);

  Future<List<Course>> call(String universityId) {
    return repository.getUniversityCourses(universityId);
  }
}
