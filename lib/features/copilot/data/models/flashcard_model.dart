import 'package:mwanachuo/features/copilot/domain/entities/flashcard_entity.dart';

class FlashcardModel extends FlashcardEntity {
  const FlashcardModel({
    required super.id,
    required super.noteId,
    required super.question,
    required super.answer,
    required super.difficulty,
    required super.createdAt,
  });

  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      id: json['id'] as String,
      noteId: json['note_id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      difficulty: json['difficulty'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'note_id': noteId,
      'question': question,
      'answer': answer,
      'difficulty': difficulty,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
