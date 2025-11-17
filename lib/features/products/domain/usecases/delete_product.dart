import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/products/domain/repositories/product_repository.dart';

/// Use case for deleting a product
class DeleteProduct implements UseCase<void, DeleteProductParams> {
  final ProductRepository repository;

  DeleteProduct(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteProductParams params) async {
    return await repository.deleteProduct(params.productId);
  }
}

class DeleteProductParams extends Equatable {
  final String productId;

  const DeleteProductParams({required this.productId});

  @override
  List<Object?> get props => [productId];
}

