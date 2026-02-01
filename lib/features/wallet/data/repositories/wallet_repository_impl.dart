import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/network/network_info.dart';
import 'package:mwanachuo/features/wallet/data/datasources/wallet_remote_data_source.dart';
import 'package:mwanachuo/features/wallet/domain/entities/wallet_entity.dart';
import 'package:mwanachuo/features/wallet/domain/entities/wallet_transaction_entity.dart';
import 'package:mwanachuo/features/wallet/domain/repositories/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  WalletRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, WalletEntity>> getWallet() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteWallet = await remoteDataSource.getWallet();
        return Right(remoteWallet);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }

  @override
  Future<Either<Failure, List<WalletTransactionEntity>>>
  getTransactions() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteTransactions = await remoteDataSource.getTransactions();
        return Right(remoteTransactions);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }

  @override
  Future<Either<Failure, String>> initiateTopUp({
    required double amount,
    required String phone,
    required String provider,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final orderId = await remoteDataSource.initiateTopUp(
          amount: amount,
          phone: phone,
          provider: provider,
        );
        return Right(orderId);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deductBalance({
    required double amount,
    required String description,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deductBalance(
          amount: amount,
          description: description,
        );
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }
}
