import 'package:mwanachuo/features/copilot/domain/entities/note_entity.dart';

class NoteModel extends NoteEntity {
  const NoteModel({
    required super.id,
    required super.title,
    super.description,
    required super.courseId,
    required super.uploadedBy,
    required super.fileUrl,
    required super.fileSize,
    required super.fileType,
    super.yearRelevance,
    required super.studyReadinessScore,
    required super.downloadCount,
    required super.viewCount,
    required super.isOfficial,
    required super.createdAt,
    required super.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      courseId: json['course_id'] as String,
      uploadedBy: json['uploaded_by'] as String,
      fileUrl: json['file_url'] as String,
      fileSize: json['file_size'] as int,
      fileType: json['file_type'] as String,
      yearRelevance: json['year_relevance'] as int?,
      studyReadinessScore: (json['study_readiness_score'] as num).toDouble(),
      downloadCount: json['download_count'] as int,
      viewCount: json['view_count'] as int,
      isOfficial: json['is_official'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'course_id': courseId,
      'uploaded_by': uploadedBy,
      'file_url': fileUrl,
      'file_size': fileSize,
      'file_type': fileType,
      'year_relevance': yearRelevance,
      'study_readiness_score': studyReadinessScore,
      'download_count': downloadCount,
      'view_count': viewCount,
      'is_official': isOfficial,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  NoteModel copyWith({
    String? id,
    String? title,
    String? description,
    String? courseId,
    String? uploadedBy,
    String? fileUrl,
    int? fileSize,
    String? fileType,
    int? yearRelevance,
    double? studyReadinessScore,
    int? downloadCount,
    int? viewCount,
    bool? isOfficial,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      courseId: courseId ?? this.courseId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      yearRelevance: yearRelevance ?? this.yearRelevance,
      studyReadinessScore: studyReadinessScore ?? this.studyReadinessScore,
      downloadCount: downloadCount ?? this.downloadCount,
      viewCount: viewCount ?? this.viewCount,
      isOfficial: isOfficial ?? this.isOfficial,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
