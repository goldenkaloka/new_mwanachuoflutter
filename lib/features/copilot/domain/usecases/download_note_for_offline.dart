import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/copilot/domain/repositories/copilot_repository.dart';

class DownloadNoteForOffline {
  final CopilotRepository repository;

  DownloadNoteForOffline(this.repository);

  Future<Either<Failure, String>> call(String noteId) async {
    return await repository.downloadNoteForOffline(noteId);
  }
}
