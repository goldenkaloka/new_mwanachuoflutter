import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/food/domain/entities/restaurant.dart';
import 'package:mwanachuo/features/food/domain/entities/food_item.dart';
import 'package:mwanachuo/features/food/domain/entities/rider.dart';

abstract class FoodRepository {
  Future<Either<Failure, List<Restaurant>>> getRestaurants({int limit = 20, int offset = 0});
  Future<Either<Failure, List<FoodItem>>> getMenu(String restaurantId);
  Future<Either<Failure, void>> placeOrder({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required double lat,
    required double lng,
  });
  Future<Either<Failure, void>> registerRestaurant({
    required String name,
    required String description,
    required String address,
    required String phone,
    required String category,
  });
  Future<Either<Failure, Rider>> getRiderForOrder(String orderId);
  Stream<Map<String, dynamic>> watchOrder(String orderId);
}
