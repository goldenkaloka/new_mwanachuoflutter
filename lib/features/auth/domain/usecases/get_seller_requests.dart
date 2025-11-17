import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/auth/domain/entities/seller_request_entity.dart';
import 'package:mwanachuo/features/auth/domain/repositories/auth_repository.dart';

class GetSellerRequests implements UseCase<List<SellerRequestEntity>, GetSellerRequestsParams> {
  final AuthRepository repository;

  GetSellerRequests(this.repository);

  @override
  Future<Either<Failure, List<SellerRequestEntity>>> call(GetSellerRequestsParams params) async {
    return await repository.getSellerRequests(status: params.status);
  }
}

class GetSellerRequestsParams extends Equatable {
  final String? status; // pending, approved, rejected, or null for all

  const GetSellerRequestsParams({this.status});

  @override
  List<Object?> get props => [status];
}





