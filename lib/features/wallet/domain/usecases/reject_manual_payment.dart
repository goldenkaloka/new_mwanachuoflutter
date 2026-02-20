import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/wallet/domain/repositories/wallet_repository.dart';

class RejectManualPayment implements UseCase<void, RejectManualPaymentParams> {
  final WalletRepository repository;

  RejectManualPayment(this.repository);

  @override
  Future<Either<Failure, void>> call(RejectManualPaymentParams params) async {
    return await repository.rejectManualPayment(
      params.requestId,
      adminNote: params.adminNote,
    );
  }
}

class RejectManualPaymentParams extends Equatable {
  final String requestId;
  final String? adminNote;

  const RejectManualPaymentParams({required this.requestId, this.adminNote});

  @override
  List<Object?> get props => [requestId, adminNote];
}
