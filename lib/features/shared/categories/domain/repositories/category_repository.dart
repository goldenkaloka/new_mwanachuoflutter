import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/shared/categories/domain/entities/category_entity.dart';

/// Category repository interface
abstract class CategoryRepository {
  /// Get all active product categories
  Future<Either<Failure, List<ProductCategoryEntity>>> getProductCategories();

  /// Get all active product conditions
  Future<Either<Failure, List<ProductConditionEntity>>> getProductConditions();
}

