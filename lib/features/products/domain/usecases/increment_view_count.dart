import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/products/domain/repositories/product_repository.dart';

/// Use case for incrementing product view count
class IncrementViewCount implements UseCase<void, IncrementViewCountParams> {
  final ProductRepository repository;

  IncrementViewCount(this.repository);

  @override
  Future<Either<Failure, void>> call(IncrementViewCountParams params) async {
    return await repository.incrementViewCount(params.productId);
  }
}

class IncrementViewCountParams extends Equatable {
  final String productId;

  const IncrementViewCountParams({required this.productId});

  @override
  List<Object?> get props => [productId];
}

