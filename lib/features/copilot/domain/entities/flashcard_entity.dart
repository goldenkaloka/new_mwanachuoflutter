class FlashcardEntity {
  final String id;
  final String noteId;
  final String question;
  final String answer;
  final String difficulty; // 'easy', 'medium', 'hard'
  final DateTime createdAt;

  const FlashcardEntity({
    required this.id,
    required this.noteId,
    required this.question,
    required this.answer,
    required this.difficulty,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashcardEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
