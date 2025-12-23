import '../repositories/mwanachuomind_repository.dart';

class SendQueryUseCase {
  final MwanachuomindRepository repository;

  SendQueryUseCase(this.repository);

  Stream<String> call({
    required String query,
    required String courseId,
    List<Map<String, String>>? history,
  }) {
    return repository.chatStream(
      query: query,
      courseId: courseId,
      history: history,
    );
  }
}
