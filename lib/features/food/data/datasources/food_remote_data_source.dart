import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mwanachuo/features/food/domain/entities/restaurant.dart';
import 'package:mwanachuo/features/food/domain/entities/food_item.dart';
import 'package:mwanachuo/features/food/domain/entities/food_additive.dart';
import 'package:mwanachuo/features/food/domain/entities/rider.dart';
import 'package:mwanachuo/features/food/domain/entities/rider_job.dart';
import 'package:mwanachuo/features/food/domain/entities/food_order.dart';
import 'package:mwanachuo/features/food/domain/entities/order_item.dart';

abstract class FoodRemoteDataSource {
  Future<List<Restaurant>> getRestaurants({int limit = 20, int offset = 0, double? userLat, double? userLng});
  Future<List<FoodItem>> getMenu(String restaurantId);
  Future<String> placeOrder({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required double lat,
    required double lng,
    String? droppingPoint,
    String? notes,
    required String logisticsType,
  });
  Future<Restaurant?> getUserRestaurant();
  Future<String> uploadRestaurantImage(dynamic imageFile);
  Future<void> registerRestaurant({
    required String name,
    required String description,
    required String address,
    required String phone,
    required String category,
    String? imageUrl,
    String? ownerId,
    double? lat,
    double? lng,
  });

  Future<List<Map<String, dynamic>>> getSellers();
  Future<Rider> getRiderForOrder(String orderId);
  Future<FoodOrder> getOrderDetails(String orderId);
  Stream<Map<String, dynamic>> watchOrder(String orderId);
  Future<List<FoodOrder>> getOrdersForRestaurant(String restaurantId);
  Future<void> updateOrderStatus(String orderId, FoodOrderStatus status, {String? rejectionReason});
  Future<String?> getUserUniversityId();
  Future<bool> checkLocationEligibility({
    required String universityId,
    required double lat,
    required double lng,
  });
  // ─── Rider methods ───────────────────────────────────────────────────────────
  Future<void> toggleRiderOnline(bool isOnline);
  Future<Rider?> getCurrentRiderProfile();
  Future<FoodOrder?> getRiderActiveJob();
  Stream<List<RiderJob>> streamPendingJobs();
  Future<void> acceptJob(String orderId);
  Future<void> declineJob(String jobId);
  Future<void> updateRiderLocation(double lat, double lng);
  Future<void> updateOrderStatusAsRider(String orderId, FoodOrderStatus status);
  Future<void> markDelivered(String orderId, String otp);
  
  // ─── Menu Management ───────────────────────────────────────────────────────
  Future<void> addFoodItem(FoodItem item);
  Future<void> updateFoodItem(FoodItem item);
  Future<void> deleteFoodItem(String itemId);
  Future<void> addFoodAdditive(FoodAdditive additive);
  Future<void> updateFoodAdditive(FoodAdditive additive);
  Future<void> deleteFoodAdditive(String additiveId);
  
  // ─── Dispatch method ─────────────────────────────────────────────────────────
  Future<void> findAndAssignNearbyRider(FoodOrder order);
}

class FoodRemoteDataSourceImpl implements FoodRemoteDataSource {
  final SupabaseClient supabaseClient;

  FoodRemoteDataSourceImpl({required this.supabaseClient});

  String get _currentUserId => supabaseClient.auth.currentUser!.id;

  // ─── Rider helpers ──────────────────────────────────────────────────────────
  Future<String?> _getRiderId() async {
    final data = await supabaseClient
        .from('riders')
        .select('id')
        .eq('user_id', _currentUserId)
        .maybeSingle();
    return data?['id']?.toString();
  }

  // ─── Existing implementations ───────────────────────────────────────────────
  @override
  Future<List<Map<String, dynamic>>> getSellers() async {
    final response = await supabaseClient
        .from('users')
        .select('id, full_name, email')
        .eq('role', 'seller');
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<Rider> getRiderForOrder(String orderId) async {
    try {
      final response = await supabaseClient
          .from('orders')
          .select('riders(*, users(full_name, avatar_url, phone_number))')
          .eq('id', orderId)
          .single();

      final riderData = response['riders'];
      if (riderData == null) throw Exception('No rider assigned to this order');
      final userData = riderData['users'];

      return Rider(
        id: riderData['id'].toString(),
        name: userData['full_name']?.toString() ?? 'Rider',
        phone: userData['phone_number']?.toString(),
        vehicleType: riderData['vehicle_type']?.toString() ?? 'Bicycle',
        rating: riderData['rating'] != null ? (riderData['rating'] as num).toDouble() : 5.0,
        avatarUrl: userData['avatar_url']?.toString(),
        isOnline: riderData['is_online'] as bool? ?? false,
      );
    } catch (e) {
      final riderResponse = await supabaseClient.from('riders').select('*, users(full_name)').limit(1).single();
      final userData = riderResponse['users'];
      return Rider(
        id: riderResponse['id'],
        name: userData['full_name'] ?? 'Available Rider',
        vehicleType: riderResponse['vehicle_type'] ?? 'Motorcycle',
        rating: (riderResponse['rating'] as num?)?.toDouble() ?? 4.8,
        phone: null,
        avatarUrl: null,
        isOnline: riderResponse['is_online'] as bool? ?? false,
      );
    }
  }

  @override
  Future<FoodOrder> getOrderDetails(String orderId) async {
    final response = await supabaseClient
        .from('orders')
        .select('*, order_items(*, food_items(name)), student:student_id(full_name, phone_number), restaurants(lat, lng)')
        .eq('id', orderId)
        .single();
    return _parseOrder(response);
  }

  @override
  Future<List<Restaurant>> getRestaurants({int limit = 20, int offset = 0, double? userLat, double? userLng}) async {
    try {
      final response = await supabaseClient.rpc('get_restaurants_with_distance', params: {
        'p_limit': limit,
        'p_offset': offset,
        'p_lat': userLat,
        'p_lng': userLng,
      });

      final List<dynamic> data = response is List ? response : [response];

      return data.map<Restaurant>((json) {
        final map = json as Map<String, dynamic>;
        return Restaurant(
          id: map['id'].toString(),
          name: map['name']?.toString() ?? '',
          description: map['description']?.toString(),
          imageUrl: map['image_url']?.toString(),
          address: map['address']?.toString(),
          phone: map['phone']?.toString(),
          category: map['category']?.toString(),
          rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
          latitude: map['lat'] != null ? (map['lat'] as num).toDouble() : 0.0,
          longitude: map['lng'] != null ? (map['lng'] as num).toDouble() : 0.0,
          isActive: map['is_active'] as bool? ?? true,
          deliveryTime: map['delivery_time']?.toString(),
          deliveryFee: map['delivery_fee'] != null ? (map['delivery_fee'] as num).toDouble() : null,
          distanceMeters: map['distance_meters'] != null ? (map['distance_meters'] as num).toDouble() : null,
        );
      }).toList();
    } catch (e) {
      final response = await supabaseClient
          .from('restaurants')
          .select('id, name, description, image_url, address, phone, category, rating, is_active, delivery_time, delivery_fee')
          .eq('is_active', true)
          .range(offset, offset + limit - 1);

      return (response as List).map<Restaurant>((json) {
        final map = json as Map<String, dynamic>;
        return Restaurant(
          id: map['id'].toString(),
          name: map['name']?.toString() ?? '',
          description: map['description']?.toString(),
          imageUrl: map['image_url']?.toString(),
          address: map['address']?.toString(),
          phone: map['phone']?.toString(),
          category: map['category']?.toString(),
          rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
          latitude: 0.0,
          longitude: 0.0,
          isActive: map['is_active'] as bool? ?? true,
          deliveryTime: map['delivery_time']?.toString(),
          deliveryFee: map['delivery_fee'] != null ? (map['delivery_fee'] as num).toDouble() : null,
        );
      }).toList();
    }
  }

  @override
  Future<List<FoodItem>> getMenu(String restaurantId) async {
    final response = await supabaseClient
        .from('food_items')
        .select('*, food_additives(*)')
        .eq('restaurant_id', restaurantId)
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      final additives = (json['food_additives'] as List?)?.map((a) => FoodAdditive(
        id: a['id'],
        foodItemId: a['food_item_id'],
        name: a['name'],
        price: (a['price'] as num).toDouble(),
        isAvailable: a['is_available'] ?? true,
      )).toList();

      return FoodItem(
        id: json['id'],
        restaurantId: json['restaurant_id'],
        name: json['name'],
        description: json['description'],
        price: (json['price'] as num).toDouble(),
        imageUrl: json['image_url'],
        category: json['category'],
        isAvailable: json['is_available'],
        additives: additives,
      );
    }).toList();
  }

  @override
  Future<String> placeOrder({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required double lat,
    required double lng,
    String? droppingPoint,
    String? notes,
    required String logisticsType,
  }) async {
    // Generate a 6-digit OTP for delivery confirmation
    final otp = (100000 + Random().nextInt(900000)).toString();

    final orderResponse = await supabaseClient.from('orders').insert({
      'student_id': _currentUserId,
      'restaurant_id': restaurantId,
      'total_amount': totalAmount,
      'delivery_location': 'POINT($lng $lat)',
      'delivery_lat': lat,
      'delivery_lng': lng,
      'status': 'pending',
      'dropping_point': droppingPoint,
      'notes': notes,
      'logistics_type': logisticsType,
      'delivery_otp': otp,
    }).select().single();

    final orderId = orderResponse['id'];

    final orderItems = items.map((item) => {
      'order_id': orderId,
      'food_item_id': item['food_item_id'],
      'quantity': item['quantity'] ?? 1,
      'unit_price': item['price'],
      'selected_additives': item['selected_additives'] ?? [],
    }).toList();

    if (orderItems.isNotEmpty) {
      await supabaseClient.from('order_items').insert(orderItems);
    }

    await supabaseClient.rpc('lock_funds', params: {
      'p_order_id': orderId,
      'p_user_id': _currentUserId,
      'p_amount': totalAmount,
    });

    return orderId.toString();
  }

  @override
  Future<Restaurant?> getUserRestaurant() async {
    final response = await supabaseClient
        .from('restaurants')
        .select()
        .eq('owner_id', _currentUserId)
        .maybeSingle();

    if (response == null) return null;

    return Restaurant(
      id: response['id'].toString(),
      name: response['name']?.toString() ?? '',
      description: response['description']?.toString(),
      imageUrl: response['image_url']?.toString(),
      address: response['address']?.toString(),
      phone: response['phone']?.toString(),
      category: response['category']?.toString(),
      rating: response['rating'] != null ? (response['rating'] as num).toDouble() : null,
      latitude: 0.0,
      longitude: 0.0,
      isActive: response['is_active'] as bool? ?? true,
      deliveryTime: response['delivery_time']?.toString(),
      deliveryFee: response['delivery_fee'] != null ? (response['delivery_fee'] as num).toDouble() : null,
    );
  }

  @override
  Future<String> uploadRestaurantImage(dynamic imageFile) async {
    final fileName = 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'food/$_currentUserId/$fileName';
    await supabaseClient.storage.from('food').upload(path, imageFile);
    return supabaseClient.storage.from('food').getPublicUrl(path);
  }

  @override
  Future<void> registerRestaurant({
    required String name,
    required String description,
    required String address,
    required String phone,
    required String category,
    String? imageUrl,
    String? ownerId,
    double? lat,
    double? lng,
  }) async {
    final latitude = lat ?? -6.7924;
    final longitude = lng ?? 39.2023;
    
    await supabaseClient.from('restaurants').insert({
      'name': name,
      'description': description,
      'address': address,
      'phone': phone,
      'category': category,
      'image_url': imageUrl,
      'is_active': false,
      'owner_id': ownerId ?? _currentUserId,
      'lat': latitude,
      'lng': longitude,
      'location': 'POINT($longitude $latitude)',
    });
  }

  @override
  Stream<Map<String, dynamic>> watchOrder(String orderId) {
    return supabaseClient
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((event) => event.first);
  }

  @override
  Future<List<FoodOrder>> getOrdersForRestaurant(String restaurantId) async {
    final response = await supabaseClient
        .from('orders')
        .select('*, order_items(*, food_items(name)), student:student_id(full_name, phone_number), restaurants(lat, lng)')
        .eq('restaurant_id', restaurantId)
        .order('created_at', ascending: false);

    return (response as List).map<FoodOrder>((json) => _parseOrder(json)).toList();
  }

  @override
  Future<void> updateOrderStatus(String orderId, FoodOrderStatus status, {String? rejectionReason}) async {
    final updates = <String, dynamic>{
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (rejectionReason != null) updates['rejection_reason'] = rejectionReason;
    await supabaseClient.from('orders').update(updates).eq('id', orderId);

    // Send push notification to Customer
    try {
      final orderResponse = await supabaseClient.from('orders').select('student_id, restaurants(name)').eq('id', orderId).single();
      final customerId = orderResponse['student_id'] as String;
      final restaurantName = orderResponse['restaurants']?['name'] as String? ?? 'Restaurant';
      
      String message = '';
      String title = 'Order Update';
      switch (status) {
        case FoodOrderStatus.confirmed:
          message = 'Your order from $restaurantName has been confirmed.';
          break;
        case FoodOrderStatus.preparing:
          message = '$restaurantName is preparing your order.';
          break;
        case FoodOrderStatus.outForDelivery:
          message = 'Your order is out for delivery! Track your rider live.';
          break;
        case FoodOrderStatus.delivered:
          title = 'Order Delivered';
          message = 'Your order has been safely delivered. Enjoy your meal!';
          break;
        case FoodOrderStatus.cancelled:
          title = 'Order Cancelled';
          message = 'Your order was cancelled. Reason: ${rejectionReason ?? 'Unknown'}';
          break;
        default:
          return; // No notification for other statuses
      }

      await supabaseClient.rpc('send_immediate_push_notification', params: {
        'p_user_id': customerId,
        'p_title': title,
        'p_message': message,
        'p_type': 'order',
        'p_action_url': '/live-tracking',
        'p_metadata': {'order_id': orderId, 'type': 'order'},
      });
    } catch (_) {}
  }

  @override
  Future<bool> checkLocationEligibility({
    required String universityId,
    required double lat,
    required double lng,
  }) async {
    final response = await supabaseClient.rpc('is_location_in_university', params: {
      'p_university_id': universityId,
      'p_lat': lat,
      'p_lng': lng,
    });
    return response as bool;
  }

  @override
  Future<String?> getUserUniversityId() async {
    final response = await supabaseClient
        .from('users')
        .select('primary_university_id')
        .eq('id', _currentUserId)
        .single();
    return response['primary_university_id']?.toString();
  }

  // ─── Rider method implementations ─────────────────────────────────────────────
  @override
  Future<void> toggleRiderOnline(bool isOnline) async {
    final riderId = await _getRiderId();
    if (riderId == null) return;
    await supabaseClient.from('riders').update({'is_online': isOnline}).eq('id', riderId);
  }

  @override
  Future<Rider?> getCurrentRiderProfile() async {
    final data = await supabaseClient
        .from('riders')
        .select('*, users(full_name, avatar_url, phone_number)')
        .eq('user_id', _currentUserId)
        .maybeSingle();

    if (data == null) return null;
    final userData = data['users'];
    return Rider(
      id: data['id'].toString(),
      name: userData['full_name']?.toString() ?? 'Rider',
      phone: userData['phone_number']?.toString(),
      vehicleType: data['vehicle_type']?.toString() ?? 'Foot',
      rating: data['rating'] != null ? (data['rating'] as num).toDouble() : 5.0,
      avatarUrl: userData['avatar_url']?.toString(),
      isOnline: data['is_online'] as bool? ?? false,
    );
  }

  @override
  Future<FoodOrder?> getRiderActiveJob() async {
    final riderId = await _getRiderId();
    if (riderId == null) return null;

    final data = await supabaseClient
        .from('orders')
        .select('*, order_items(*, food_items(name)), restaurants(name, address, lat, lng), student:student_id(full_name, phone_number)')
        .eq('rider_id', riderId)
        .inFilter('status', ['riderAssigned', 'preparing', 'readyForPickup', 'pickedUp', 'outForDelivery', 'nearYou'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return _parseOrder(data);
  }

  @override
  Stream<List<RiderJob>> streamPendingJobs() async* {
    if (supabaseClient.auth.currentUser == null) {
      yield [];
      return;
    }

    final riderId = await _getRiderId();
    if (riderId == null) {
      yield [];
      return;
    }

    // Since stream() doesn't support joins, we fetch job IDs and then enrich them
    yield* supabaseClient
        .from('rider_jobs')
        .stream(primaryKey: ['id'])
        .eq('rider_id', riderId)
        .asyncMap((rows) async {
          final pendingRows = rows.where((r) => r['status'] == 'pending').toList();
          if (pendingRows.isEmpty) return [];

          final List<RiderJob> jobs = [];
          for (var r in pendingRows) {
            try {
              final orderId = r['order_id'];
              // Join with orders, restaurants and users to get normalized data
              final orderData = await supabaseClient
                  .from('orders')
                  .select('*, restaurants(name, address, lat, lng), student:student_id(full_name, phone_number)')
                  .eq('id', orderId)
                  .single();

              final restaurant = orderData['restaurants'];
              final student = orderData['student'];

              jobs.add(RiderJob(
                id: r['id'].toString(),
                orderId: orderId.toString(),
                riderId: r['rider_id'].toString(),
                status: RiderJobStatus.pending,
                createdAt: DateTime.parse(r['created_at']),
                restaurantName: restaurant?['name']?.toString(),
                restaurantAddress: restaurant?['address']?.toString(),
                restaurantLat: restaurant?['lat'] != null ? (restaurant!['lat'] as num).toDouble() : null,
                restaurantLng: restaurant?['lng'] != null ? (restaurant!['lng'] as num).toDouble() : null,
                deliveryLat: orderData['delivery_lat'] != null ? (orderData['delivery_lat'] as num).toDouble() : null,
                deliveryLng: orderData['delivery_lng'] != null ? (orderData['delivery_lng'] as num).toDouble() : null,
                totalAmount: orderData['total_amount'] != null ? (orderData['total_amount'] as num).toDouble() : null,
                estimatedEarnings: r['estimated_earnings'] != null ? (r['estimated_earnings'] as num).toDouble() : null,
                distanceKm: r['distance_km'] != null ? (r['distance_km'] as num).toDouble() : null,
                droppingPoint: orderData['dropping_point']?.toString(),
                customerName: student?['full_name']?.toString(),
                customerPhone: student?['phone_number']?.toString(),
              ));
            } catch (_) {
              // If order details fail to fetch, skip this job
              continue;
            }
          }
          return jobs;
        });
  }

  @override
  Future<void> acceptJob(String orderId) async {
    final riderId = await _getRiderId();
    if (riderId == null) throw Exception('Rider profile not found');

    await supabaseClient.from('orders').update({
      'rider_id': riderId,
      'status': 'riderAssigned',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);

    await supabaseClient
        .from('rider_jobs')
        .update({'status': 'accepted'})
        .eq('order_id', orderId)
        .eq('rider_id', riderId);
  }

  @override
  Future<void> declineJob(String jobId) async {
    await supabaseClient
        .from('rider_jobs')
        .update({'status': 'declined'})
        .eq('id', jobId);
  }

  @override
  Future<void> updateRiderLocation(double lat, double lng) async {
    final riderId = await _getRiderId();
    if (riderId == null) return;
    await supabaseClient.from('riders').update({
      'current_location': 'POINT($lng $lat)',
    }).eq('id', riderId);
  }

  @override
  Future<void> updateOrderStatusAsRider(String orderId, FoodOrderStatus status) async {
    await supabaseClient.from('orders').update({
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  @override
  Future<void> markDelivered(String orderId, String otp) async {
    final order = await supabaseClient
        .from('orders')
        .select('delivery_otp')
        .eq('id', orderId)
        .single();

    final storedOtp = order['delivery_otp']?.toString();
    if (storedOtp == null || storedOtp != otp) {
      throw Exception('Invalid delivery OTP. Please check with the customer.');
    }

    await supabaseClient.from('orders').update({
      'status': 'delivered',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  // ─── Parse helpers ────────────────────────────────────────────────────────────
  FoodOrder _parseOrder(Map<String, dynamic> json) {
    final items = (json['order_items'] as List?)?.map((item) => OrderItem(
      id: item['id'],
      orderId: item['order_id'],
      foodItemId: item['food_item_id'],
      foodName: item['food_items']?['name'] ?? 'Unknown Item',
      quantity: item['quantity'],
      unitPrice: (item['unit_price'] as num).toDouble(),
      selectedAdditives: item['selected_additives'] ?? [],
    )).toList();

    final restaurant = json['restaurants'];

    return FoodOrder(
      id: json['id'].toString(),
      studentId: json['student_id'] ?? '',
      restaurantId: json['restaurant_id'] ?? '',
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: _parseOrderStatus(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      rejectionReason: json['rejection_reason'],
      items: items,
      studentPhone: json['student']?['phone_number'],
      deliveryLat: json['delivery_lat'] != null ? (json['delivery_lat'] as num).toDouble() : null,
      deliveryLng: json['delivery_lng'] != null ? (json['delivery_lng'] as num).toDouble() : null,
      restaurantLat: restaurant?['lat'] != null ? (restaurant!['lat'] as num).toDouble() : null,
      restaurantLng: restaurant?['lng'] != null ? (restaurant!['lng'] as num).toDouble() : null,
      deliveryOtp: json['delivery_otp']?.toString(),
      droppingPoint: json['dropping_point']?.toString(),
    );
  }

  FoodOrderStatus _parseOrderStatus(String status) {
    return FoodOrderStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => FoodOrderStatus.pending,
    );
  }

  // ─── Dispatch implementation ────────────────────────────────────────────────
  @override
  Future<void> findAndAssignNearbyRider(FoodOrder order) async {
    if (order.restaurantLat == null || order.restaurantLng == null) return;
    
    // 1. Get the closest online rider using PostGIS RPC (within 10km by default)
    final response = await supabaseClient.rpc('get_nearby_riders', params: {
      'p_lat': order.restaurantLat,
      'p_lng': order.restaurantLng,
      'p_radius_km': 10.0,
    });
    
    final List<dynamic> nearbyRiders = response;
    if (nearbyRiders.isEmpty) return; // No riders available
    
    // Nearest rider is the first one because the RPC orders by distance ASC
    final closestRider = nearbyRiders.first;
    final closestRiderId = closestRider['rider_id'].toString();
    final distanceKm = (closestRider['distance_km'] as num).toDouble();

    // 3. Insert into rider_jobs (Normalized: only order_id, rider_id, status and calculated earnings)
    await supabaseClient.from('rider_jobs').insert({
      'order_id': order.id,
      'rider_id': closestRiderId,
      'status': 'pending',
      // Rough estimation: 1000 TZS base + 500 TZS per km
      'estimated_earnings': 1000 + (distanceKm * 500),
      'distance_km': double.parse(distanceKm.toStringAsFixed(1)),
    });

    // 4. Notify rider via push notification
    try {
      final restResp = await supabaseClient.from('restaurants').select('name').eq('id', order.restaurantId).single();
      await supabaseClient.rpc('send_immediate_push_notification', params: {
        'p_user_id': closestRiderId,
        'p_title': 'New Delivery Request!',
        'p_message': 'Tap to view new delivery from ${restResp['name']}',
        'p_type': 'delivery',
        'p_action_url': '/rider-jobs',
        'p_metadata': {'order_id': order.id, 'type': 'delivery'},
      });
    } catch (_) {}
  }

  // ─── Menu Management Implementations ────────────────────────────────────────
  @override
  Future<void> addFoodItem(FoodItem item) async {
    await supabaseClient.from('food_items').insert({
      'restaurant_id': item.restaurantId,
      'name': item.name,
      'description': item.description,
      'price': item.price,
      'image_url': item.imageUrl,
      'category': item.category,
      'is_available': item.isAvailable,
    });
  }

  @override
  Future<void> updateFoodItem(FoodItem item) async {
    await supabaseClient.from('food_items').update({
      'name': item.name,
      'description': item.description,
      'price': item.price,
      'image_url': item.imageUrl,
      'category': item.category,
      'is_available': item.isAvailable,
    }).eq('id', item.id);
  }

  @override
  Future<void> deleteFoodItem(String itemId) async {
    await supabaseClient.from('food_items').delete().eq('id', itemId);
  }

  @override
  Future<void> addFoodAdditive(FoodAdditive additive) async {
    await supabaseClient.from('food_additives').insert({
      'food_item_id': additive.foodItemId,
      'name': additive.name,
      'price': additive.price,
      'is_available': additive.isAvailable,
    });
  }

  @override
  Future<void> updateFoodAdditive(FoodAdditive additive) async {
    await supabaseClient.from('food_additives').update({
      'name': additive.name,
      'price': additive.price,
      'is_available': additive.isAvailable,
    }).eq('id', additive.id);
  }

  @override
  Future<void> deleteFoodAdditive(String additiveId) async {
    await supabaseClient.from('food_additives').delete().eq('id', additiveId);
  }
}
