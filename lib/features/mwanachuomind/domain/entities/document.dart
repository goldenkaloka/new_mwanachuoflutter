import 'package:equatable/equatable.dart';

class Document extends Equatable {
  final String id;
  final String courseId;
  final String title;
  final String filePath;
  final DateTime createdAt;

  const Document({
    required this.id,
    required this.courseId,
    required this.title,
    required this.filePath,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, courseId, title, filePath, createdAt];
}
