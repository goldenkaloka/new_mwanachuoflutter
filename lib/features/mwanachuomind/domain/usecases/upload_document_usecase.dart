import 'dart:io';
import '../entities/document.dart';
import '../repositories/mwanachuomind_repository.dart';

class UploadDocumentUseCase {
  final MwanachuomindRepository repository;

  UploadDocumentUseCase(this.repository);

  Future<Document> call({
    required String courseId,
    required String title,
    required File file,
  }) {
    return repository.uploadDocument(courseId: courseId, title: title, file: file);
  }
}
