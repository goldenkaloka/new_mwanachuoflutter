import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/products/domain/entities/product_entity.dart';
import 'package:mwanachuo/features/products/domain/repositories/product_repository.dart';

/// Use case for getting a product by ID
class GetProductById implements UseCase<ProductEntity, GetProductByIdParams> {
  final ProductRepository repository;

  GetProductById(this.repository);

  @override
  Future<Either<Failure, ProductEntity>> call(
    GetProductByIdParams params,
  ) async {
    return await repository.getProductById(params.productId);
  }
}

class GetProductByIdParams extends Equatable {
  final String productId;

  const GetProductByIdParams({required this.productId});

  @override
  List<Object?> get props => [productId];
}

