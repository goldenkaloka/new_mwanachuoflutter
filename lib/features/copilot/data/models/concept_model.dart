import 'package:mwanachuo/features/copilot/domain/entities/concept_entity.dart';

class ConceptModel extends ConceptEntity {
  const ConceptModel({
    required super.id,
    required super.noteId,
    required super.conceptText,
    super.conceptType,
    super.pageNumber,
    super.context,
    required super.createdAt,
  });

  factory ConceptModel.fromJson(Map<String, dynamic> json) {
    return ConceptModel(
      id: json['id'] as String,
      noteId: json['note_id'] as String,
      conceptText: json['concept_text'] as String,
      conceptType: json['concept_type'] as String?,
      pageNumber: json['page_number'] as int?,
      context: json['context'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'note_id': noteId,
      'concept_text': conceptText,
      'concept_type': conceptType,
      'page_number': pageNumber,
      'context': context,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
