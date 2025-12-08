import 'package:equatable/equatable.dart';

/// Product category entity
class ProductCategoryEntity extends Equatable {
  final String id;
  final String name;
  final String? icon;
  final String? description;
  final int displayOrder;
  final bool isActive;

  const ProductCategoryEntity({
    required this.id,
    required this.name,
    this.icon,
    this.description,
    this.displayOrder = 0,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, icon, description, displayOrder, isActive];
}

/// Product condition entity
class ProductConditionEntity extends Equatable {
  final String id;
  final String name;
  final int displayOrder;
  final bool isActive;

  const ProductConditionEntity({
    required this.id,
    required this.name,
    this.displayOrder = 0,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, name, displayOrder, isActive];
}

