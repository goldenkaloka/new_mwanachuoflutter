import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/services/domain/repositories/service_repository.dart';

class DeleteService implements UseCase<void, DeleteServiceParams> {
  final ServiceRepository repository;

  DeleteService(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteServiceParams params) async {
    return await repository.deleteService(params.serviceId);
  }
}

class DeleteServiceParams extends Equatable {
  final String serviceId;

  const DeleteServiceParams({required this.serviceId});

  @override
  List<Object?> get props => [serviceId];
}

