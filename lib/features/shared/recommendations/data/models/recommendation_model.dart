import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_entity.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_type.dart';

/// Model for recommendation data
class RecommendationModel extends RecommendationEntity {
  const RecommendationModel({
    required super.itemId,
    required super.type,
    required super.similarityScore,
    required super.matchReasons,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      itemId: json['id'] as String,
      type: RecommendationTypeExtension.fromString(
        json['type'] as String? ?? 'product',
      ),
      similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0.0,
      matchReasons:
          json['match_reasons'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': itemId,
      'type': type.value,
      'similarity_score': similarityScore,
      'match_reasons': matchReasons,
    };
  }

  RecommendationEntity toEntity() {
    return RecommendationEntity(
      itemId: itemId,
      type: type,
      similarityScore: similarityScore,
      matchReasons: matchReasons,
    );
  }
}







