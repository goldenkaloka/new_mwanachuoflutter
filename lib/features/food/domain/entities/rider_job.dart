import 'package:equatable/equatable.dart';

enum RiderJobStatus { pending, accepted, declined, expired }

class RiderJob extends Equatable {
  final String id;
  final String orderId;
  final String riderId;
  final RiderJobStatus status;
  final DateTime createdAt;
  // Enriched order info for display
  final String? restaurantName;
  final String? restaurantAddress;
  final double? restaurantLat;
  final double? restaurantLng;
  final double? deliveryLat;
  final double? deliveryLng;
  final double? totalAmount;
  final double? estimatedEarnings;
  final double? distanceKm;
  final String? droppingPoint;

  const RiderJob({
    required this.id,
    required this.orderId,
    required this.riderId,
    required this.status,
    required this.createdAt,
    this.restaurantName,
    this.restaurantAddress,
    this.restaurantLat,
    this.restaurantLng,
    this.deliveryLat,
    this.deliveryLng,
    this.totalAmount,
    this.estimatedEarnings,
    this.distanceKm,
    this.droppingPoint,
  });

  @override
  List<Object?> get props => [
    id, orderId, riderId, status, createdAt,
    restaurantName, restaurantAddress, totalAmount, distanceKm,
  ];
}
