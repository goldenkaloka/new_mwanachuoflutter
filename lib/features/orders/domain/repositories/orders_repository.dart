import 'package:dartz/dartz.dart' hide Order;
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/orders/domain/entities/order.dart';
import 'package:mwanachuo/features/orders/domain/entities/campus_spot.dart';

abstract class OrdersRepository {
  Future<Either<Failure, List<Order>>> getOrders();
  Future<Either<Failure, Order>> getOrder(String orderId);
  Future<Either<Failure, List<Order>>> getVendorOrders();
  Future<Either<Failure, List<Order>>> getRunnerOrders();
  Future<Either<Failure, List<Order>>> getAvailableRunnerJobs();
  Future<Either<Failure, Order>> createOrder(Order order);
  Future<Either<Failure, void>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  );
  Future<Either<Failure, void>> claimOrder(String orderId);
  Future<Either<Failure, List<CampusSpot>>> getCampusSpots(
    String? universityId,
  );
}
