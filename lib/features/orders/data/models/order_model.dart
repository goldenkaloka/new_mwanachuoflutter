import 'package:mwanachuo/features/orders/domain/entities/order.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.userId,
    required super.vendorId,
    super.runnerId,
    required super.items,
    required super.status,
    required super.totalAmount,
    required super.paymentStatus,
    super.deliverySpotId,
    super.meetingNotes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vendorId: json['vendor_id'] as String,
      runnerId: json['runner_id'] as String?,
      items: (json['order_items'] as List? ?? [])
          .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      status: OrderStatus.fromString(json['status'] as String? ?? 'pending'),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      deliverySpotId: json['delivery_spot_id'] as String?,
      meetingNotes: json['meeting_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vendor_id': vendorId,
      'runner_id': runnerId,
      'status': status.value,
      'total_amount': totalAmount,
      'payment_status': paymentStatus,
      'delivery_spot_id': deliverySpotId,
      'meeting_notes': meetingNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.quantity,
    required super.priceAtTime,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String? ?? 'Product',
      quantity: json['quantity'] as int,
      priceAtTime: (json['price_at_time'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price_at_time': priceAtTime,
    };
  }
}
