class ConceptEntity {
  final String id;
  final String noteId;
  final String conceptText;
  final String? conceptType; // 'key_term', 'formula', 'definition', 'example'
  final int? pageNumber;
  final String? context;
  final DateTime createdAt;

  const ConceptEntity({
    required this.id,
    required this.noteId,
    required this.conceptText,
    this.conceptType,
    this.pageNumber,
    this.context,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConceptEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
