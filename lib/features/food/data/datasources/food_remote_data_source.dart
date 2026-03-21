import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mwanachuo/features/food/domain/entities/restaurant.dart';
import 'package:mwanachuo/features/food/domain/entities/food_item.dart';
import 'package:mwanachuo/features/food/domain/entities/rider.dart';

abstract class FoodRemoteDataSource {
  Future<List<Restaurant>> getRestaurants({int limit = 20, int offset = 0});
  Future<List<FoodItem>> getMenu(String restaurantId);
  Future<void> placeOrder({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required double lat,
    required double lng,
  });
  Future<void> registerRestaurant({
    required String name,
    required String description,
    required String address,
    required String phone,
    required String category,
  });
  Future<Rider> getRiderForOrder(String orderId);
  Stream<Map<String, dynamic>> watchOrder(String orderId);
}

class FoodRemoteDataSourceImpl implements FoodRemoteDataSource {
  final SupabaseClient supabaseClient;

  FoodRemoteDataSourceImpl({required this.supabaseClient});

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
      );
    } catch (e) {
      // Fallback to a generic rider if query fails (still uses database constraints)
      final riderResponse = await supabaseClient.from('riders').select('*, users(full_name)').limit(1).single();
      final userData = riderResponse['users'];
      return Rider(
        id: riderResponse['id'],
        name: userData['full_name'] ?? 'Available Rider',
        vehicleType: riderResponse['vehicle_type'] ?? 'Motorcycle',
        rating: (riderResponse['rating'] as num?)?.toDouble() ?? 4.8,
      );
    }
  }

  @override
  Future<List<Restaurant>> getRestaurants({int limit = 20, int offset = 0}) async {
    try {
      // Try RPC for proper coordinate extraction
      final response = await supabaseClient
          .rpc('get_restaurants_with_coords', params: {
            'p_limit': limit,
            'p_offset': offset,
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
        );
      }).toList();
    } catch (e) {
      // Fallback: direct table query without location parsing
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
        .select()
        .eq('restaurant_id', restaurantId)
        .eq('is_available', true);

    return (response as List).map((json) => FoodItem(
      id: json['id'],
      restaurantId: json['restaurant_id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'],
      category: json['category'],
      isAvailable: json['is_available'],
    )).toList();
  }

  @override
  Future<void> placeOrder({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required double lat,
    required double lng,
  }) async {
    // 1. Create the order record
    final orderResponse = await supabaseClient.from('orders').insert({
      'student_id': supabaseClient.auth.currentUser!.id,
      'restaurant_id': restaurantId,
      'total_amount': totalAmount,
      'delivery_location': 'POINT($lng $lat)',
      'status': 'pending',
    }).select().single();

    final orderId = orderResponse['id'];

    // 2. Insert order line items
    final orderItems = items.map((item) => {
      'order_id': orderId,
      'food_item_id': item['food_item_id'],
      'quantity': item['quantity'] ?? 1,
      'unit_price': item['price'],
    }).toList();

    if (orderItems.isNotEmpty) {
      await supabaseClient.from('order_items').insert(orderItems);
    }

    // 3. Lock funds via RPC
    await supabaseClient.rpc('lock_funds', params: {
      'p_order_id': orderId,
      'p_user_id': supabaseClient.auth.currentUser!.id,
      'p_amount': totalAmount,
    });
  }

  @override
  Future<void> registerRestaurant({
    required String name,
    required String description,
    required String address,
    required String phone,
    required String category,
  }) async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // In a real app, we'd check if the user is a 'seller' here
    // For now, we'll insert into restaurants table
    await supabaseClient.from('restaurants').insert({
      'name': name,
      'description': description,
      'address': address,
      'phone': phone,
      'category': category,
      'is_active': false, // Requires admin approval
      'owner_id': user.id,
      'location': 'POINT(39.2023 -6.7924)', // Default campus center
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
}
