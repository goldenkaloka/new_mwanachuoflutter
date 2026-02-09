import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/products/data/models/product_order_model.dart';
import 'package:mwanachuo/features/products/data/models/product_offer_model.dart';
import 'package:mwanachuo/features/products/domain/entities/product_order.dart';
import 'package:mwanachuo/features/products/domain/entities/product_offer.dart';

abstract class ProductCartRemoteDataSource {
  // Order operations
  Future<ProductOrderModel> createOrder({
    required String sellerId,
    required List<ProductOrderItem> items,
    required PaymentMethod paymentMethod,
    required DeliveryMethod deliveryMethod,
    String? deliverySpotId,
    String? deliveryAddress,
    String? deliveryPhone,
    String? conversationId,
    String? offerId,
    double? agreedPrice,
  });

  Future<List<ProductOrderModel>> getMyOrders({
    ProductOrderStatus? status,
    int? limit,
    int? offset,
  });

  Future<List<ProductOrderModel>> getSellerOrders({
    ProductOrderStatus? status,
    int? limit,
    int? offset,
  });

  Future<ProductOrderModel> getOrderById(String orderId);

  Future<ProductOrderModel> updateOrderStatus({
    required String orderId,
    required ProductOrderStatus status,
    String? trackingNotes,
  });

  Future<void> cancelOrder(String orderId);

  Future<void> requestRefund({required String orderId, required String reason});

  // Offer operations
  Future<ProductOfferModel> createOffer({
    required String productId,
    required String sellerId,
    required String conversationId,
    required double offerAmount,
    required double originalPrice,
    String? message,
  });

  Future<ProductOfferModel> acceptOffer(String offerId);
  Future<ProductOfferModel> declineOffer(String offerId);

  Future<ProductOfferModel> counterOffer({
    required String offerId,
    required double counterAmount,
    String? message,
  });

  Future<ProductOfferModel> getOfferById(String offerId);

  Future<List<ProductOfferModel>> getProductOffers({
    required String productId,
    OfferStatus? status,
  });

  Future<List<OfferHistoryItemModel>> getOfferHistory(String offerId);
}

class ProductCartRemoteDataSourceImpl implements ProductCartRemoteDataSource {
  final SupabaseClient supabaseClient;

  ProductCartRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<ProductOrderModel> createOrder({
    required String sellerId,
    required List<ProductOrderItem> items,
    required PaymentMethod paymentMethod,
    required DeliveryMethod deliveryMethod,
    String? deliverySpotId,
    String? deliveryAddress,
    String? deliveryPhone,
    String? conversationId,
    String? offerId,
    double? agreedPrice,
  }) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) throw const ServerException('User not authenticated');

      // Calculate total
      final totalAmount = items.fold<double>(
        0,
        (sum, item) => sum + (item.priceAtTime * item.quantity),
      );

      // Create order
      final orderData = {
        'buyer_id': userId,
        'seller_id': sellerId,
        'total_amount': totalAmount,
        'original_price': items.first.priceAtTime,
        'agreed_price': agreedPrice,
        'payment_method': paymentMethod.value,
        'payment_status': 'pending',
        'delivery_method': deliveryMethod.value,
        'delivery_spot_id': deliverySpotId,
        'delivery_address': deliveryAddress,
        'delivery_phone': deliveryPhone,
        'order_status': 'pending_payment',
        'conversation_id': conversationId,
        'offer_id': offerId,
      };

      final orderResponse = await supabaseClient
          .from('product_orders')
          .insert(orderData)
          .select()
          .single();

      // Create order items
      final orderItemsData = items.map((item) {
        return {
          'order_id': orderResponse['id'],
          'product_id': item.productId,
          'product_snapshot': item.productSnapshot,
          'quantity': item.quantity,
          'price_at_time': item.priceAtTime,
        };
      }).toList();

      await supabaseClient.from('product_order_items').insert(orderItemsData);

      // Fetch complete order with items
      final completeOrder = await getOrderById(orderResponse['id'] as String);

      return completeOrder;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ProductOrderModel>> getMyOrders({
    ProductOrderStatus? status,
    int? limit,
    int? offset,
  }) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) throw const ServerException('User not authenticated');

      var query = supabaseClient
          .from('product_orders')
          .select('*, product_order_items(*)')
          .eq('buyer_id', userId);

      if (status != null) {
        query = query.eq('order_status', status.value);
      }

      var transformQuery = query.order('created_at', ascending: false);

      if (limit != null) {
        transformQuery = transformQuery.limit(limit);
      }

      if (offset != null) {
        transformQuery = transformQuery.range(
          offset,
          offset + (limit ?? 10) - 1,
        );
      }

      final response = await transformQuery;

      return (response as List)
          .map(
            (json) => ProductOrderModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ProductOrderModel>> getSellerOrders({
    ProductOrderStatus? status,
    int? limit,
    int? offset,
  }) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) throw const ServerException('User not authenticated');

      var query = supabaseClient
          .from('product_orders')
          .select('*, product_order_items(*)')
          .eq('seller_id', userId);

      if (status != null) {
        query = query.eq('order_status', status.value);
      }

      var transformQuery = query.order('created_at', ascending: false);

      if (limit != null) {
        transformQuery = transformQuery.limit(limit);
      }

      if (offset != null) {
        transformQuery = transformQuery.range(
          offset,
          offset + (limit ?? 10) - 1,
        );
      }

      final response = await transformQuery;

      return (response as List)
          .map(
            (json) => ProductOrderModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ProductOrderModel> getOrderById(String orderId) async {
    try {
      final response = await supabaseClient
          .from('product_orders')
          .select('*, product_order_items(*)')
          .eq('id', orderId)
          .single();

      return ProductOrderModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ProductOrderModel> updateOrderStatus({
    required String orderId,
    required ProductOrderStatus status,
    String? trackingNotes,
  }) async {
    try {
      final updateData = {'order_status': status.value};
      if (trackingNotes != null) {
        updateData['tracking_notes'] = trackingNotes;
      }

      await supabaseClient
          .from('product_orders')
          .update(updateData)
          .eq('id', orderId);

      return await getOrderById(orderId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    try {
      await supabaseClient
          .from('product_orders')
          .update({'order_status': 'cancelled'})
          .eq('id', orderId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> requestRefund({
    required String orderId,
    required String reason,
  }) async {
    try {
      // Get current notes first
      final order = await getOrderById(orderId);
      final currentNotes = order.trackingNotes ?? '';
      final newNotes =
          '$currentNotes\n[${DateTime.now().toIso8601String()}] Refund Requested: $reason'
              .trim();

      await supabaseClient
          .from('product_orders')
          .update({
            'order_status':
                'refunded', // Or 'refund_requested' if we had that state
            'tracking_notes': newNotes,
          })
          .eq('id', orderId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ==================== OFFER OPERATIONS ====================

  @override
  Future<ProductOfferModel> createOffer({
    required String productId,
    required String sellerId,
    required String conversationId,
    required double offerAmount,
    required double originalPrice,
    String? message,
  }) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) throw const ServerException('User not authenticated');

      final offerData = {
        'product_id': productId,
        'buyer_id': userId,
        'seller_id': sellerId,
        'conversation_id': conversationId,
        'offer_amount': offerAmount,
        'original_price': originalPrice,
        'message': message,
        'status': 'pending',
      };

      final response = await supabaseClient
          .from('product_offers')
          .insert(offerData)
          .select()
          .single();

      // Add to offer history
      await supabaseClient.from('offer_history').insert({
        'offer_id': response['id'],
        'user_id': userId,
        'amount': offerAmount,
        'message': message,
        'action': 'offer',
      });

      return ProductOfferModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ProductOfferModel> acceptOffer(String offerId) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) throw const ServerException('User not authenticated');

      // Get offer details
      final offer = await getOfferById(offerId);

      // Update offer status
      final response = await supabaseClient
          .from('product_offers')
          .update({'status': 'accepted'})
          .eq('id', offerId)
          .select()
          .single();

      // Add to offer history
      await supabaseClient.from('offer_history').insert({
        'offer_id': offerId,
        'user_id': userId,
        'amount': offer.offerAmount,
        'action': 'accept',
      });

      return ProductOfferModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ProductOfferModel> declineOffer(String offerId) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) throw const ServerException('User not authenticated');

      final offer = await getOfferById(offerId);

      final response = await supabaseClient
          .from('product_offers')
          .update({'status': 'declined'})
          .eq('id', offerId)
          .select()
          .single();

      await supabaseClient.from('offer_history').insert({
        'offer_id': offerId,
        'user_id': userId,
        'amount': offer.offerAmount,
        'action': 'decline',
      });

      return ProductOfferModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ProductOfferModel> counterOffer({
    required String offerId,
    required double counterAmount,
    String? message,
  }) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) throw const ServerException('User not authenticated');

      final response = await supabaseClient
          .from('product_offers')
          .update({
            'status': 'countered',
            'offer_amount': counterAmount,
            'message': message,
          })
          .eq('id', offerId)
          .select()
          .single();

      await supabaseClient.from('offer_history').insert({
        'offer_id': offerId,
        'user_id': userId,
        'amount': counterAmount,
        'message': message,
        'action': 'counter',
      });

      return ProductOfferModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ProductOfferModel> getOfferById(String offerId) async {
    try {
      final response = await supabaseClient
          .from('product_offers')
          .select()
          .eq('id', offerId)
          .single();

      return ProductOfferModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ProductOfferModel>> getProductOffers({
    required String productId,
    OfferStatus? status,
  }) async {
    try {
      var query = supabaseClient
          .from('product_offers')
          .select()
          .eq('product_id', productId);

      if (status != null) {
        query = query.eq('status', status.value);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map(
            (json) => ProductOfferModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<OfferHistoryItemModel>> getOfferHistory(String offerId) async {
    try {
      final response = await supabaseClient
          .from('offer_history')
          .select()
          .eq('offer_id', offerId)
          .order('created_at', ascending: true);

      return (response as List)
          .map(
            (json) =>
                OfferHistoryItemModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
