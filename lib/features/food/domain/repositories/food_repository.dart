import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/food/domain/entities/restaurant.dart';
import 'package:mwanachuo/features/food/domain/entities/food_item.dart';
import 'package:mwanachuo/features/food/domain/entities/rider.dart';
import 'package:mwanachuo/features/food/domain/entities/rider_job.dart';
import 'package:mwanachuo/features/food/domain/entities/food_order.dart';

abstract class FoodRepository {
  Future<Either<Failure, List<Restaurant>>> getRestaurants({int limit = 20, int offset = 0, double? userLat, double? userLng});
  Future<Either<Failure, String>> placeOrder({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required double lat,
    required double lng,
    String? droppingPoint,
    String? notes,
    required String logisticsType,
  });
  Future<Either<Failure, List<FoodItem>>> getMenu(String restaurantId);
  Future<Either<Failure, Restaurant?>> getUserRestaurant();
  Future<Either<Failure, String>> uploadRestaurantImage(Object imageFile);
  Future<Either<Failure, void>> registerRestaurant({
    required String name,
    required String description,
    required String address,
    required String phone,
    required String category,
    String? imageUrl,
  });
  Future<Either<Failure, Rider>> getRiderForOrder(String orderId);
  Future<Either<Failure, FoodOrder>> getOrderDetails(String orderId);
  Stream<Map<String, dynamic>> watchOrder(String orderId);
  Future<Either<Failure, List<FoodOrder>>> getOrdersForRestaurant(String restaurantId);
  Future<Either<Failure, void>> updateOrderStatus(String orderId, FoodOrderStatus status, {String? rejectionReason});
  Future<Either<Failure, String?>> getUserUniversityId();
  Future<Either<Failure, bool>> checkLocationEligibility({
    required String universityId,
    required double lat,
    required double lng,
  });

  // ─── Rider-specific methods ───────────────────────────────────────────────
  Future<Either<Failure, void>> toggleRiderOnline(bool isOnline);
  Future<Either<Failure, Rider?>> getCurrentRiderProfile();
  Future<Either<Failure, FoodOrder?>> getRiderActiveJob();
  Stream<List<RiderJob>> streamPendingJobs();
  Future<Either<Failure, void>> acceptJob(String orderId);
  Future<Either<Failure, void>> declineJob(String jobId);
  Future<Either<Failure, void>> updateRiderLocation(double lat, double lng);
  Future<Either<Failure, void>> updateOrderStatusAsRider(String orderId, FoodOrderStatus status);
  Future<Either<Failure, void>> markDelivered(String orderId, String otp);
  Future<Either<Failure, void>> findAndAssignNearbyRider(FoodOrder order);
}
