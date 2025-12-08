import 'package:mwanachuo/features/shared/categories/domain/entities/category_entity.dart';

/// Product category model (data layer)
class ProductCategoryModel extends ProductCategoryEntity {
  const ProductCategoryModel({
    required super.id,
    required super.name,
    super.icon,
    super.description,
    super.displayOrder,
    super.isActive,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      description: json['description'] as String?,
      displayOrder: (json['display_order'] as int?) ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }
}

/// Product condition model (data layer)
class ProductConditionModel extends ProductConditionEntity {
  const ProductConditionModel({
    required super.id,
    required super.name,
    super.displayOrder,
    super.isActive,
  });

  factory ProductConditionModel.fromJson(Map<String, dynamic> json) {
    return ProductConditionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      displayOrder: (json['display_order'] as int?) ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }
}

