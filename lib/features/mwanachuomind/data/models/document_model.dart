import '../../domain/entities/document.dart';

class DocumentModel extends Document {
  const DocumentModel({
    required super.id,
    required super.courseId,
    required super.title,
    required super.filePath,
    required super.createdAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      courseId: json['course_id'],
      title: json['title'],
      filePath: json['file_path'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'file_path': filePath,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
