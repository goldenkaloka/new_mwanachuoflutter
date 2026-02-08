import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/orders/data/datasources/orders_remote_data_source.dart';
import 'package:mwanachuo/features/orders/data/models/order_model.dart';
import 'package:mwanachuo/features/orders/data/models/campus_spot_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  final SupabaseClient supabaseClient;

  OrdersRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<OrderModel>> getOrders() async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) throw ServerException('User not authenticated');

      final response = await supabaseClient
          .from(DatabaseConstants.ordersTable)
          .select('*, order_items(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<OrderModel> getOrder(String orderId) async {
    try {
      final response = await supabaseClient
          .from(DatabaseConstants.ordersTable)
          .select('*, order_items(*)')
          .eq('id', orderId)
          .single();

      return OrderModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<OrderModel>> getVendorOrders() async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) throw ServerException('User not authenticated');

      final response = await supabaseClient
          .from(DatabaseConstants.ordersTable)
          .select('*, order_items(*)')
          .eq('vendor_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<OrderModel>> getRunnerOrders() async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) throw ServerException('User not authenticated');

      final response = await supabaseClient
          .from(DatabaseConstants.ordersTable)
          .select('*, order_items(*)')
          .eq('runner_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<OrderModel>> getAvailableRunnerJobs() async {
    try {
      final response = await supabaseClient
          .from(DatabaseConstants.ordersTable)
          .select('*, order_items(*)')
          .filter('runner_id', 'is', null)
          .eq('status', 'ready_for_pickup')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      final orderData = order.toJson();
      orderData.remove('items'); // JSON key is 'items' in entity, but not in DB

      final response = await supabaseClient
          .from(DatabaseConstants.ordersTable)
          .insert(orderData)
          .select()
          .single();

      final orderId = response['id'] as String;

      final itemsData = order.items.map((item) {
        final map = (item as OrderItemModel).toJson();
        map['order_id'] = orderId;
        map.remove('id'); // Let DB generate UUID
        return map;
      }).toList();

      await supabaseClient
          .from(DatabaseConstants.orderItemsTable)
          .insert(itemsData);

      return await getOrder(orderId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await supabaseClient
          .from(DatabaseConstants.ordersTable)
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> claimOrder(String orderId) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) throw ServerException('User not authenticated');

      await supabaseClient
          .from(DatabaseConstants.ordersTable)
          .update({
            'runner_id': userId,
            'status': 'on_way',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .filter('runner_id', 'is', null);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<CampusSpotModel>> getCampusSpots(String? universityId) async {
    try {
      var query = supabaseClient
          .from(DatabaseConstants.campusSpotsTable)
          .select();
      if (universityId != null) {
        query = query.eq('university_id', universityId);
      }
      final response = await query;
      return (response as List)
          .map((json) => CampusSpotModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
