import 'package:equatable/equatable.dart';

enum OrderLogisticsType { bolt, internal }
enum FoodOrderStatus { pending, confirmed, preparing, readyForPickup, pickedUp, nearYou, completed, cancelled }

class FoodOrder extends Equatable {
  final String id;
  final String studentId;
  final String restaurantId;
  final double totalAmount;
  final OrderLogisticsType? logisticsType;
  final FoodOrderStatus status;
  final String? trackingLink;
  final DateTime createdAt;

  const FoodOrder({
    required this.id,
    required this.studentId,
    required this.restaurantId,
    required this.totalAmount,
    this.logisticsType,
    required this.status,
    this.trackingLink,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, studentId, restaurantId, totalAmount, logisticsType, status, trackingLink, createdAt];
}
