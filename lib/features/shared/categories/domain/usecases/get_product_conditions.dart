import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/categories/domain/entities/category_entity.dart';
import 'package:mwanachuo/features/shared/categories/domain/repositories/category_repository.dart';

/// Use case for getting product conditions
class GetProductConditions implements UseCase<List<ProductConditionEntity>, NoParams> {
  final CategoryRepository repository;

  GetProductConditions(this.repository);

  @override
  Future<Either<Failure, List<ProductConditionEntity>>> call(NoParams params) async {
    return await repository.getProductConditions();
  }
}

