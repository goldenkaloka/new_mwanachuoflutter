class TagEntity {
  final String id;
  final String noteId;
  final String tagName;
  final bool isAiGenerated;
  final DateTime createdAt;

  const TagEntity({
    required this.id,
    required this.noteId,
    required this.tagName,
    required this.isAiGenerated,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
