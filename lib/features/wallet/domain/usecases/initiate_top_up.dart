import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/wallet/domain/repositories/wallet_repository.dart';

class InitiateTopUp implements UseCase<String, InitiateTopUpParams> {
  final WalletRepository repository;

  InitiateTopUp(this.repository);

  @override
  Future<Either<Failure, String>> call(InitiateTopUpParams params) async {
    return await repository.initiateTopUp(
      amount: params.amount,
      phone: params.phone,
      provider: params.provider,
    );
  }
}

class InitiateTopUpParams extends Equatable {
  final double amount;
  final String phone;
  final String provider;

  const InitiateTopUpParams({
    required this.amount,
    required this.phone,
    required this.provider,
  });

  @override
  List<Object?> get props => [amount, phone, provider];
}
