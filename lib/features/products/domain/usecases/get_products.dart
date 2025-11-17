import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/products/domain/entities/product_entity.dart';
import 'package:mwanachuo/features/products/domain/repositories/product_repository.dart';

/// Use case for getting products
class GetProducts implements UseCase<List<ProductEntity>, GetProductsParams> {
  final ProductRepository repository;

  GetProducts(this.repository);

  @override
  Future<Either<Failure, List<ProductEntity>>> call(
    GetProductsParams params,
  ) async {
    return await repository.getProducts(
      category: params.category,
      universityId: params.universityId,
      sellerId: params.sellerId,
      isFeatured: params.isFeatured,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetProductsParams extends Equatable {
  final String? category;
  final String? universityId;
  final String? sellerId;
  final bool? isFeatured;
  final int? limit;
  final int? offset;

  const GetProductsParams({
    this.category,
    this.universityId,
    this.sellerId,
    this.isFeatured,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [
        category,
        universityId,
        sellerId,
        isFeatured,
        limit,
        offset,
      ];
}

