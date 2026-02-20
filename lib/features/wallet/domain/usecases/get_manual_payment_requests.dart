import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/wallet/domain/entities/manual_payment_request_entity.dart';
import 'package:mwanachuo/features/wallet/domain/repositories/wallet_repository.dart';

class GetManualPaymentRequests
    implements UseCase<List<ManualPaymentRequestEntity>, NoParams> {
  final WalletRepository repository;

  GetManualPaymentRequests(this.repository);

  @override
  Future<Either<Failure, List<ManualPaymentRequestEntity>>> call(
    NoParams params,
  ) async {
    return await repository.getManualPaymentRequests();
  }
}
