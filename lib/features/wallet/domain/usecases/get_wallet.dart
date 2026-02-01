import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:mwanachuo/features/wallet/domain/repositories/wallet_repository.dart';

class GetWallet implements UseCase<WalletEntity, NoParams> {
  final WalletRepository repository;

  GetWallet(this.repository);

  @override
  Future<Either<Failure, WalletEntity>> call(NoParams params) async {
    return await repository.getWallet();
  }
}
