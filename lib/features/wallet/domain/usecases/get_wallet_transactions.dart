import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/wallet/domain/entities/wallet_transaction_entity.dart';
import 'package:mwanachuo/features/wallet/domain/repositories/wallet_repository.dart';

class GetWalletTransactions
    implements UseCase<List<WalletTransactionEntity>, NoParams> {
  final WalletRepository repository;

  GetWalletTransactions(this.repository);

  @override
  Future<Either<Failure, List<WalletTransactionEntity>>> call(
    NoParams params,
  ) async {
    return await repository.getTransactions();
  }
}
