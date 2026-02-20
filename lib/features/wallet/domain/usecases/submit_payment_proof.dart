import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/wallet/domain/entities/manual_payment_request_entity.dart';
import 'package:mwanachuo/features/wallet/domain/repositories/wallet_repository.dart';

class SubmitPaymentProof
    implements UseCase<ManualPaymentRequestEntity, SubmitPaymentProofParams> {
  final WalletRepository repository;

  SubmitPaymentProof(this.repository);

  @override
  Future<Either<Failure, ManualPaymentRequestEntity>> call(
    SubmitPaymentProofParams params,
  ) async {
    return await repository.submitPaymentProof(
      amount: params.amount,
      transactionRef: params.transactionRef,
      payerPhone: params.payerPhone,
      type: params.type,
      metadata: params.metadata,
    );
  }
}

class SubmitPaymentProofParams extends Equatable {
  final double amount;
  final String transactionRef;
  final String payerPhone;
  final String type;
  final Map<String, dynamic>? metadata;

  const SubmitPaymentProofParams({
    required this.amount,
    required this.transactionRef,
    required this.payerPhone,
    required this.type,
    this.metadata,
  });

  @override
  List<Object?> get props => [
    amount,
    transactionRef,
    payerPhone,
    type,
    metadata,
  ];
}
