import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/auth/domain/repositories/auth_repository.dart';

class ApproveSellerRequest implements UseCase<void, ApproveSellerRequestParams> {
  final AuthRepository repository;

  ApproveSellerRequest(this.repository);

  @override
  Future<Either<Failure, void>> call(ApproveSellerRequestParams params) async {
    return await repository.approveSellerRequest(
      requestId: params.requestId,
      adminId: params.adminId,
      notes: params.notes,
    );
  }
}

class ApproveSellerRequestParams extends Equatable {
  final String requestId;
  final String adminId;
  final String? notes;

  const ApproveSellerRequestParams({
    required this.requestId,
    required this.adminId,
    this.notes,
  });

  @override
  List<Object?> get props => [requestId, adminId, notes];
}

