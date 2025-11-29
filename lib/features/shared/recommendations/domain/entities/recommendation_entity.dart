import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_type.dart';

/// Entity representing a recommended item
class RecommendationEntity extends Equatable {
  final String itemId;
  final RecommendationType type;
  final double similarityScore; // 0.0 to 1.0
  final Map<String, dynamic>
  matchReasons; // e.g., {'category': 0.4, 'seller': 0.3, 'university': 0.2, 'price': 0.1}

  const RecommendationEntity({
    required this.itemId,
    required this.type,
    required this.similarityScore,
    required this.matchReasons,
  });

  @override
  List<Object?> get props => [itemId, type, similarityScore, matchReasons];
}


