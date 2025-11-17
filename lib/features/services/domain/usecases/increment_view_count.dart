import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/services/domain/repositories/service_repository.dart';

class IncrementViewCount implements UseCase<void, IncrementViewCountParams> {
  final ServiceRepository repository;

  IncrementViewCount(this.repository);

  @override
  Future<Either<Failure, void>> call(IncrementViewCountParams params) async {
    return await repository.incrementViewCount(params.serviceId);
  }
}

class IncrementViewCountParams extends Equatable {
  final String serviceId;

  const IncrementViewCountParams({required this.serviceId});

  @override
  List<Object?> get props => [serviceId];
}

