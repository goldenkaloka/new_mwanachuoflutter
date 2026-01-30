import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/promotions/domain/entities/promotion_entity.dart';

abstract class PromotionState extends Equatable {
  const PromotionState();

  @override
  List<Object?> get props => [];
}

class PromotionInitial extends PromotionState {}

class PromotionsLoading extends PromotionState {}

class PromotionsLoaded extends PromotionState {
  final List<PromotionEntity> promotions;

  const PromotionsLoaded({required this.promotions});

  @override
  List<Object?> get props => [promotions];
}

class PromotionError extends PromotionState {
  final String message;

  const PromotionError({required this.message});

  @override
  List<Object?> get props => [message];
}

class PromotionCreated extends PromotionState {
  final PromotionEntity promotion;

  const PromotionCreated({required this.promotion});

  @override
  List<Object?> get props => [promotion];
}
