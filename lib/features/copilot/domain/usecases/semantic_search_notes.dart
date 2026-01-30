import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/copilot/domain/entities/note_entity.dart';
import 'package:mwanachuo/features/copilot/domain/repositories/copilot_repository.dart';

class SemanticSearchNotes {
  final CopilotRepository repository;

  SemanticSearchNotes(this.repository);

  Future<Either<Failure, List<NoteEntity>>> call({
    required String query,
    required String courseId,
    int limit = 10,
  }) async {
    return await repository.semanticSearch(
      query: query,
      courseId: courseId,
      limit: limit,
    );
  }
}
