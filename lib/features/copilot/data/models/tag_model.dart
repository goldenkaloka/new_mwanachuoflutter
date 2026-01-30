import 'package:mwanachuo/features/copilot/domain/entities/tag_entity.dart';

class TagModel extends TagEntity {
  const TagModel({
    required super.id,
    required super.noteId,
    required super.tagName,
    required super.isAiGenerated,
    required super.createdAt,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'] as String,
      noteId: json['note_id'] as String,
      tagName: json['tag_name'] as String,
      isAiGenerated: json['is_ai_generated'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'note_id': noteId,
      'tag_name': tagName,
      'is_ai_generated': isAiGenerated,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
