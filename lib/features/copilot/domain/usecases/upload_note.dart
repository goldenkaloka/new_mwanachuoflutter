import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/copilot/domain/repositories/copilot_repository.dart';

class UploadNote {
  final CopilotRepository repository;

  UploadNote(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required File file,
    required String noteId,
    required String courseId,
    String? title,
  }) async {
    return await repository.uploadAndAnalyze(
      file: file,
      noteId: noteId,
      courseId: courseId,
      title: title,
    );
  }
}
