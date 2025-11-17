import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/services/domain/entities/service_entity.dart';
import 'package:mwanachuo/features/services/domain/repositories/service_repository.dart';

class GetServiceById implements UseCase<ServiceEntity, GetServiceByIdParams> {
  final ServiceRepository repository;

  GetServiceById(this.repository);

  @override
  Future<Either<Failure, ServiceEntity>> call(
    GetServiceByIdParams params,
  ) async {
    return await repository.getServiceById(params.serviceId);
  }
}

class GetServiceByIdParams extends Equatable {
  final String serviceId;

  const GetServiceByIdParams({required this.serviceId});

  @override
  List<Object?> get props => [serviceId];
}

