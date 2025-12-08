import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/shared/categories/domain/entities/category_entity.dart';

/// Base class for category states
abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CategoryInitial extends CategoryState {}

/// Loading state
class CategoryLoading extends CategoryState {}

/// Categories and conditions loaded successfully
class CategoriesLoaded extends CategoryState {
  final List<ProductCategoryEntity> categories;
  final List<ProductConditionEntity> conditions;

  const CategoriesLoaded({
    required this.categories,
    required this.conditions,
  });

  @override
  List<Object?> get props => [categories, conditions];
}

/// Error state
class CategoryError extends CategoryState {
  final String message;

  const CategoryError(this.message);

  @override
  List<Object?> get props => [message];
}

