import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_entity.dart';

/// Base class for all recommendation states
abstract class RecommendationState extends Equatable {
  const RecommendationState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class RecommendationInitial extends RecommendationState {}

/// Loading recommendations
class RecommendationsLoading extends RecommendationState {}

/// Recommendations loaded successfully
class RecommendationsLoaded extends RecommendationState {
  final List<RecommendationEntity> recommendations;

  const RecommendationsLoaded({required this.recommendations});

  @override
  List<Object?> get props => [recommendations];
}

/// Error state
class RecommendationError extends RecommendationState {
  final String message;

  const RecommendationError({required this.message});

  @override
  List<Object?> get props => [message];
}


