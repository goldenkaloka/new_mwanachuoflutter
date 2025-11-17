import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/auth/domain/repositories/auth_repository.dart';

class RequestSellerAccess implements UseCase<void, RequestSellerAccessParams> {
  final AuthRepository repository;

  RequestSellerAccess(this.repository);

  @override
  Future<Either<Failure, void>> call(RequestSellerAccessParams params) async {
    return await repository.requestSellerAccess(
      userId: params.userId,
      reason: params.reason,
    );
  }
}

class RequestSellerAccessParams extends Equatable {
  final String userId;
  final String reason;

  const RequestSellerAccessParams({
    required this.userId,
    required this.reason,
  });

  @override
  List<Object> get props => [userId, reason];
}

