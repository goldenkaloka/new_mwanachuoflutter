import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/network/network_info.dart';
import 'package:mwanachuo/features/food/data/datasources/food_remote_data_source.dart';
import 'package:mwanachuo/features/food/domain/entities/restaurant.dart';
import 'package:mwanachuo/features/food/domain/entities/food_item.dart';
import 'package:mwanachuo/features/food/domain/entities/rider.dart';
import 'package:mwanachuo/features/food/domain/entities/rider_job.dart';
import 'package:mwanachuo/features/food/domain/entities/food_order.dart';
import 'package:mwanachuo/features/food/domain/repositories/food_repository.dart';

class FoodRepositoryImpl implements FoodRepository {
  final FoodRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  FoodRepositoryImpl({required this.remoteDataSource, required this.networkInfo});

  // ─── Helpers ────────────────────────────────────────────────────────────────
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() fn) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No Internet Connection'));
    }
    try {
      return Right(await fn());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ─── Existing methods ────────────────────────────────────────────────────────
  @override
  Future<Either<Failure, Rider>> getRiderForOrder(String orderId) =>
      _guard(() => remoteDataSource.getRiderForOrder(orderId));

  @override
  Future<Either<Failure, FoodOrder>> getOrderDetails(String orderId) =>
      _guard(() => remoteDataSource.getOrderDetails(orderId));

  @override
  Future<Either<Failure, List<Restaurant>>> getRestaurants({int limit = 20, int offset = 0, double? userLat, double? userLng}) =>
      _guard(() => remoteDataSource.getRestaurants(limit: limit, offset: offset, userLat: userLat, userLng: userLng));

  @override
  Future<Either<Failure, List<FoodItem>>> getMenu(String restaurantId) =>
      _guard(() => remoteDataSource.getMenu(restaurantId));

  @override
  Future<Either<Failure, Restaurant?>> getUserRestaurant() =>
      _guard(() => remoteDataSource.getUserRestaurant());

  @override
  Future<Either<Failure, String>> uploadRestaurantImage(Object imageFile) =>
      _guard(() => remoteDataSource.uploadRestaurantImage(imageFile));

  @override
  Future<Either<Failure, String>> placeOrder({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required double lat,
    required double lng,
    String? droppingPoint,
    String? notes,
    required String logisticsType,
  }) => _guard(() => remoteDataSource.placeOrder(
        restaurantId: restaurantId,
        items: items,
        totalAmount: totalAmount,
        lat: lat,
        lng: lng,
        droppingPoint: droppingPoint,
        notes: notes,
        logisticsType: logisticsType,
      ));

  @override
  Future<Either<Failure, void>> registerRestaurant({
    required String name,
    required String description,
    required String address,
    required String phone,
    required String category,
    String? imageUrl,
  }) => _guard(() => remoteDataSource.registerRestaurant(
        name: name,
        description: description,
        address: address,
        phone: phone,
        category: category,
        imageUrl: imageUrl,
      ));

  @override
  Stream<Map<String, dynamic>> watchOrder(String orderId) =>
      remoteDataSource.watchOrder(orderId);

  @override
  Future<Either<Failure, List<FoodOrder>>> getOrdersForRestaurant(String restaurantId) =>
      _guard(() => remoteDataSource.getOrdersForRestaurant(restaurantId));

  @override
  Future<Either<Failure, void>> updateOrderStatus(String orderId, FoodOrderStatus status, {String? rejectionReason}) =>
      _guard(() => remoteDataSource.updateOrderStatus(orderId, status, rejectionReason: rejectionReason));

  @override
  Future<Either<Failure, bool>> checkLocationEligibility({
    required String universityId,
    required double lat,
    required double lng,
  }) => _guard(() => remoteDataSource.checkLocationEligibility(
        universityId: universityId, lat: lat, lng: lng));

  @override
  Future<Either<Failure, String?>> getUserUniversityId() =>
      _guard(() => remoteDataSource.getUserUniversityId());

  // ─── Rider-specific methods ──────────────────────────────────────────────────
  @override
  Future<Either<Failure, void>> toggleRiderOnline(bool isOnline) =>
      _guard(() => remoteDataSource.toggleRiderOnline(isOnline));

  @override
  Future<Either<Failure, Rider?>> getCurrentRiderProfile() =>
      _guard(() => remoteDataSource.getCurrentRiderProfile());

  @override
  Future<Either<Failure, FoodOrder?>> getRiderActiveJob() =>
      _guard(() => remoteDataSource.getRiderActiveJob());

  @override
  Stream<List<RiderJob>> streamPendingJobs() =>
      remoteDataSource.streamPendingJobs();

  @override
  Future<Either<Failure, void>> acceptJob(String orderId) =>
      _guard(() => remoteDataSource.acceptJob(orderId));

  @override
  Future<Either<Failure, void>> declineJob(String jobId) =>
      _guard(() => remoteDataSource.declineJob(jobId));

  @override
  Future<Either<Failure, void>> updateRiderLocation(double lat, double lng) =>
      _guard(() => remoteDataSource.updateRiderLocation(lat, lng));

  @override
  Future<Either<Failure, void>> updateOrderStatusAsRider(String orderId, FoodOrderStatus status) =>
      _guard(() => remoteDataSource.updateOrderStatusAsRider(orderId, status));

  @override
  Future<Either<Failure, void>> markDelivered(String orderId, String otp) =>
      _guard(() => remoteDataSource.markDelivered(orderId, otp));

  @override
  Future<Either<Failure, void>> findAndAssignNearbyRider(FoodOrder order) =>
      _guard(() => remoteDataSource.findAndAssignNearbyRider(order));
}
