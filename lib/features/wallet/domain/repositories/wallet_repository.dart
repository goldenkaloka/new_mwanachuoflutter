import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:mwanachuo/features/wallet/domain/entities/wallet_transaction_entity.dart';
import 'package:mwanachuo/features/wallet/domain/entities/manual_payment_request_entity.dart';

abstract class WalletRepository {
  Future<Either<Failure, WalletEntity>> getWallet();
  Future<Either<Failure, List<WalletTransactionEntity>>> getTransactions();
  Future<Either<Failure, String>> initiateTopUp({
    required double amount,
    required String phone,
    required String provider,
  });
  Future<Either<Failure, void>> deductBalance({
    required double amount,
    required String description,
  });
  Future<Either<Failure, ManualPaymentRequestEntity>> submitPaymentProof({
    required double amount,
    required String transactionRef,
    required String payerPhone,
    required String type,
    Map<String, dynamic>? metadata,
  });
  Future<Either<Failure, List<ManualPaymentRequestEntity>>>
  getManualPaymentRequests();
  Future<Either<Failure, List<ManualPaymentRequestEntity>>>
  getPendingManualPaymentRequests();
  Future<Either<Failure, void>> approveManualPayment(
    String requestId, {
    String? adminNote,
  });
  Future<Either<Failure, void>> rejectManualPayment(
    String requestId, {
    String? adminNote,
  });
}
