import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/models/filter_model.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/products/domain/entities/product_entity.dart';
import 'package:mwanachuo/features/products/domain/repositories/product_repository.dart';

/// Use case for getting user's products
class GetMyProducts implements UseCase<List<ProductEntity>, GetMyProductsParams> {
  final ProductRepository repository;

  GetMyProducts(this.repository);

  @override
  Future<Either<Failure, List<ProductEntity>>> call(
    GetMyProductsParams params,
  ) async {
    return await repository.getMyProducts(
      limit: params.limit,
      offset: params.offset,
      filter: params.filter,
    );
  }
}

class GetMyProductsParams extends Equatable {
  final int? limit;
  final int? offset;
  final ProductFilter? filter;

  const GetMyProductsParams({this.limit, this.offset, this.filter});

  @override
  List<Object?> get props => [limit, offset, filter];
}

