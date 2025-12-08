import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/categories/domain/entities/category_entity.dart';
import 'package:mwanachuo/features/shared/categories/domain/repositories/category_repository.dart';

/// Use case for getting product categories
class GetProductCategories implements UseCase<List<ProductCategoryEntity>, NoParams> {
  final CategoryRepository repository;

  GetProductCategories(this.repository);

  @override
  Future<Either<Failure, List<ProductCategoryEntity>>> call(NoParams params) async {
    return await repository.getProductCategories();
  }
}

