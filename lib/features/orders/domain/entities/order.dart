import 'package:equatable/equatable.dart';

enum OrderStatus {
  pending('pending'),
  confirmed('confirmed'),
  cooking('cooking'),
  readyForPickup('ready_for_pickup'),
  onWay('on_way'),
  delivered('delivered'),
  cancelled('cancelled');

  final String value;
  const OrderStatus(this.value);

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

class Order extends Equatable {
  final String id;
  final String userId;
  final String vendorId;
  final String? runnerId;
  final List<OrderItem> items;
  final OrderStatus status;
  final double totalAmount;
  final String paymentStatus;
  final String? deliverySpotId;
  final String? meetingNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Order({
    required this.id,
    required this.userId,
    required this.vendorId,
    this.runnerId,
    required this.items,
    required this.status,
    required this.totalAmount,
    required this.paymentStatus,
    this.deliverySpotId,
    this.meetingNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    vendorId,
    runnerId,
    items,
    status,
    totalAmount,
    paymentStatus,
    deliverySpotId,
    meetingNotes,
    createdAt,
    updatedAt,
  ];
}

class OrderItem extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double priceAtTime;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.priceAtTime,
  });

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    quantity,
    priceAtTime,
  ];
}
