import 'package:mwanachuo/features/products/domain/entities/product_order.dart';

/// Product Order Model
class ProductOrderModel extends ProductOrder {
  const ProductOrderModel({
    required super.id,
    required super.buyerId,
    required super.sellerId,
    required super.totalAmount,
    super.originalPrice,
    super.agreedPrice,
    required super.paymentMethod,
    required super.paymentStatus,
    required super.deliveryMethod,
    super.deliverySpotId,
    super.deliveryAddress,
    super.deliveryPhone,
    required super.status,
    super.trackingNotes,
    super.conversationId,
    super.offerId,
    super.items,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProductOrderModel.fromJson(Map<String, dynamic> json) {
    return ProductOrderModel(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      originalPrice: json['original_price'] != null
          ? (json['original_price'] as num).toDouble()
          : null,
      agreedPrice: json['agreed_price'] != null
          ? (json['agreed_price'] as num).toDouble()
          : null,
      paymentMethod: PaymentMethod.fromString(
        json['payment_method'] as String? ?? 'cash',
      ),
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      deliveryMethod: DeliveryMethod.fromString(
        json['delivery_method'] as String? ?? 'pickup',
      ),
      deliverySpotId: json['delivery_spot_id'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      deliveryPhone: json['delivery_phone'] as String?,
      status: ProductOrderStatus.fromString(
        json['order_status'] as String? ?? 'pending_payment',
      ),
      trackingNotes: json['tracking_notes'] as String?,
      conversationId: json['conversation_id'] as String?,
      offerId: json['offer_id'] as String?,
      items: json['product_order_items'] != null
          ? (json['product_order_items'] as List)
                .map(
                  (item) => ProductOrderItemModel.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList()
          : [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'total_amount': totalAmount,
      'original_price': originalPrice,
      'agreed_price': agreedPrice,
      'payment_method': paymentMethod.value,
      'payment_status': paymentStatus,
      'delivery_method': deliveryMethod.value,
      'delivery_spot_id': deliverySpotId,
      'delivery_address': deliveryAddress,
      'delivery_phone': deliveryPhone,
      'order_status': status.value,
      'tracking_notes': trackingNotes,
      'conversation_id': conversationId,
      'offer_id': offerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Product Order Item Model
class ProductOrderItemModel extends ProductOrderItem {
  const ProductOrderItemModel({
    required super.id,
    required super.orderId,
    required super.productId,
    required super.productSnapshot,
    required super.quantity,
    required super.priceAtTime,
    required super.createdAt,
  });

  factory ProductOrderItemModel.fromJson(Map<String, dynamic> json) {
    return ProductOrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      productSnapshot: json['product_snapshot'] as Map<String, dynamic>? ?? {},
      quantity: json['quantity'] as int,
      priceAtTime: (json['price_at_time'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_snapshot': productSnapshot,
      'quantity': quantity,
      'price_at_time': priceAtTime,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
