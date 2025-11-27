import 'package:equatable/equatable.dart';

class SubscriptionPlanEntity extends Equatable {
  final String id;
  final String name;
  final double priceMonthly;
  final double priceYearly;
  final int? maxListings; // NULL = unlimited
  final Map<String, dynamic> features;
  final bool isActive;
  final DateTime createdAt;

  const SubscriptionPlanEntity({
    required this.id,
    required this.name,
    required this.priceMonthly,
    required this.priceYearly,
    this.maxListings,
    required this.features,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        priceMonthly,
        priceYearly,
        maxListings,
        features,
        isActive,
        createdAt,
      ];
}

