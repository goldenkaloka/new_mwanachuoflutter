import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/food/domain/entities/order_item.dart';

enum OrderLogisticsType { bolt, internal }
enum FoodOrderStatus {
  pending,
  confirmed,
  riderAssigned,
  preparing,
  readyForPickup,
  pickedUp,
  outForDelivery,
  nearYou,
  delivered,
  completed,
  cancelled,
  rejected,
}

class FoodOrder extends Equatable {
  final String id;
  final String studentId;
  final String restaurantId;
  final double totalAmount;
  final OrderLogisticsType? logisticsType;
  final FoodOrderStatus status;
  final String? trackingLink;
  final DateTime createdAt;
  final String? rejectionReason;
  final List<OrderItem>? items;
  final String? studentName;
  // Location data
  final double? deliveryLat;   // Customer's delivery location
  final double? deliveryLng;
  final double? restaurantLat; // Restaurant / pickup location
  final double? restaurantLng;
  // Delivery confirmation
  final String? deliveryOtp;
  final String? droppingPoint;

  const FoodOrder({
    required this.id,
    required this.studentId,
    required this.restaurantId,
    required this.totalAmount,
    this.logisticsType,
    required this.status,
    this.trackingLink,
    required this.createdAt,
    this.rejectionReason,
    this.items,
    this.studentName,
    this.deliveryLat,
    this.deliveryLng,
    this.restaurantLat,
    this.restaurantLng,
    this.deliveryOtp,
    this.droppingPoint,
  });

  @override
  List<Object?> get props => [
    id, studentId, restaurantId, totalAmount, logisticsType,
    status, trackingLink, createdAt, rejectionReason, items, studentName,
    deliveryLat, deliveryLng, restaurantLat, restaurantLng, deliveryOtp, droppingPoint,
  ];
}
