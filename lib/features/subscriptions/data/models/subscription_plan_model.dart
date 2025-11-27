import 'package:mwanachuo/features/subscriptions/domain/entities/subscription_plan_entity.dart';

class SubscriptionPlanModel extends SubscriptionPlanEntity {
  const SubscriptionPlanModel({
    required super.id,
    required super.name,
    required super.priceMonthly,
    required super.priceYearly,
    super.maxListings,
    required super.features,
    required super.isActive,
    required super.createdAt,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] as String,
      name: json['name'] as String,
      priceMonthly: (json['price_monthly'] as num).toDouble(),
      priceYearly: (json['price_yearly'] as num).toDouble(),
      maxListings: json['max_listings'] as int?,
      features: json['features'] as Map<String, dynamic>? ?? {},
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price_monthly': priceMonthly,
      'price_yearly': priceYearly,
      'max_listings': maxListings,
      'features': features,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

