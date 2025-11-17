import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/services/domain/entities/service_entity.dart';
import 'package:mwanachuo/features/services/domain/repositories/service_repository.dart';

class GetMyServices implements UseCase<List<ServiceEntity>, GetMyServicesParams> {
  final ServiceRepository repository;

  GetMyServices(this.repository);

  @override
  Future<Either<Failure, List<ServiceEntity>>> call(
    GetMyServicesParams params,
  ) async {
    return await repository.getMyServices(
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetMyServicesParams extends Equatable {
  final int? limit;
  final int? offset;

  const GetMyServicesParams({this.limit, this.offset});

  @override
  List<Object?> get props => [limit, offset];
}

