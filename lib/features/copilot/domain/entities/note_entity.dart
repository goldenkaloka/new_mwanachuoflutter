class NoteEntity {
  final String id;
  final String title;
  final String? description;
  final String courseId;
  final String uploadedBy;
  final String fileUrl;
  final int fileSize;
  final String fileType;
  final int? yearRelevance;
  final double studyReadinessScore;
  final int downloadCount;
  final int viewCount;
  final bool isOfficial;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteEntity({
    required this.id,
    required this.title,
    this.description,
    required this.courseId,
    required this.uploadedBy,
    required this.fileUrl,
    required this.fileSize,
    required this.fileType,
    this.yearRelevance,
    required this.studyReadinessScore,
    required this.downloadCount,
    required this.viewCount,
    required this.isOfficial,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
