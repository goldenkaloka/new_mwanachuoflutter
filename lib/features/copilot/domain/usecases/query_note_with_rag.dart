import 'package:mwanachuo/features/copilot/domain/repositories/copilot_repository.dart';

class QueryNoteWithRag {
  final CopilotRepository repository;

  QueryNoteWithRag(this.repository);

  Stream<String> call({
    required String question,
    required String courseId,
    String? noteId,
    List<Map<String, dynamic>>? history,
  }) {
    return repository.queryNoteWithRag(
      question: question,
      noteId: noteId,
      courseId: courseId,
      history: history,
    );
  }
}
