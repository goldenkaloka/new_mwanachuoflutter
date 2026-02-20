import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/wallet/domain/repositories/wallet_repository.dart';

class ApproveManualPayment
    implements UseCase<void, ApproveManualPaymentParams> {
  final WalletRepository repository;

  ApproveManualPayment(this.repository);

  @override
  Future<Either<Failure, void>> call(ApproveManualPaymentParams params) async {
    return await repository.approveManualPayment(
      params.requestId,
      adminNote: params.adminNote,
    );
  }
}

class ApproveManualPaymentParams extends Equatable {
  final String requestId;
  final String? adminNote;

  const ApproveManualPaymentParams({required this.requestId, this.adminNote});

  @override
  List<Object?> get props => [requestId, adminNote];
}
