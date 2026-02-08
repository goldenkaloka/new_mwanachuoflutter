import 'package:mwanachuo/features/orders/data/models/order_model.dart';
import 'package:mwanachuo/features/orders/data/models/campus_spot_model.dart';

abstract class OrdersRemoteDataSource {
  Future<List<OrderModel>> getOrders();
  Future<OrderModel> createOrder(OrderModel order);
  Future<OrderModel> getOrder(String orderId);
  Future<List<OrderModel>> getVendorOrders();
  Future<List<OrderModel>> getRunnerOrders();
  Future<List<OrderModel>> getAvailableRunnerJobs();
  Future<void> updateOrderStatus(String orderId, String status);
  Future<void> claimOrder(String orderId);
  Future<List<CampusSpotModel>> getCampusSpots(String? universityId);
}
