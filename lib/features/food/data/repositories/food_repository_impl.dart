import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/network/network_info.dart';
import 'package:mwanachuo/features/food/data/datasources/food_remote_data_source.dart';
import 'package:mwanachuo/features/food/domain/entities/restaurant.dart';
import 'package:mwanachuo/features/food/domain/entities/food_item.dart';
import 'package:mwanachuo/features/food/domain/entities/rider.dart';
import 'package:mwanachuo/features/food/domain/repositories/food_repository.dart';

class FoodRepositoryImpl implements FoodRepository {
  final FoodRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  FoodRepositoryImpl({required this.remoteDataSource, required this.networkInfo});

  @override
  Future<Either<Failure, Rider>> getRiderForOrder(String orderId) async {
    if (await networkInfo.isConnected) {
      try {
        final rider = await remoteDataSource.getRiderForOrder(orderId);
        return Right(rider);
      } on Exception catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }

  @override
  Future<Either<Failure, List<Restaurant>>> getRestaurants({int limit = 20, int offset = 0}) async {
    if (await networkInfo.isConnected) {
      try {
        final restaurants = await remoteDataSource.getRestaurants(limit: limit, offset: offset);
        return Right(restaurants);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }

  @override
  Future<Either<Failure, List<FoodItem>>> getMenu(String restaurantId) async {
    if (await networkInfo.isConnected) {
      try {
        final menu = await remoteDataSource.getMenu(restaurantId);
        return Right(menu);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }

  @override
  Future<Either<Failure, void>> placeOrder({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required double lat,
    required double lng,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.placeOrder(
          restaurantId: restaurantId,
          items: items,
          totalAmount: totalAmount,
          lat: lat,
          lng: lng,
        );
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }

  @override
  Future<Either<Failure, void>> registerRestaurant({
    required String name,
    required String description,
    required String address,
    required String phone,
    required String category,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.registerRestaurant(
          name: name,
          description: description,
          address: address,
          phone: phone,
          category: category,
        );
        return const Right(null);
      } on Exception catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No Internet Connection'));
    }
  }

  @override
  Stream<Map<String, dynamic>> watchOrder(String orderId) {
    return remoteDataSource.watchOrder(orderId);
  }
}
