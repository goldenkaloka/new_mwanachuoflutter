import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/copilot/domain/entities/note_entity.dart';
import 'package:mwanachuo/features/copilot/domain/repositories/copilot_repository.dart';

class GetCourseNotes {
  final CopilotRepository repository;

  GetCourseNotes(this.repository);

  Future<Either<Failure, List<NoteEntity>>> call({
    required String courseId,
    String? filterBy,
    int? year,
    int? semester,
  }) async {
    return await repository.getCourseNotes(
      courseId: courseId,
      filterBy: filterBy,
      year: year,
      semester: semester,
    );
  }
}
