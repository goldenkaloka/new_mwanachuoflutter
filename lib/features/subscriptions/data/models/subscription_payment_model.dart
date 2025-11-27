import 'package:mwanachuo/features/subscriptions/domain/entities/subscription_payment_entity.dart';

class SubscriptionPaymentModel extends SubscriptionPaymentEntity {
  const SubscriptionPaymentModel({
    required super.id,
    required super.subscriptionId,
    required super.amount,
    super.currency,
    required super.status,
    super.stripePaymentIntentId,
    super.receiptUrl,
    super.paidAt,
    required super.createdAt,
  });

  factory SubscriptionPaymentModel.fromJson(Map<String, dynamic> json) {
    PaymentStatus status;
    final statusStr = json['status'] as String;
    switch (statusStr) {
      case 'pending':
        status = PaymentStatus.pending;
        break;
      case 'succeeded':
        status = PaymentStatus.succeeded;
        break;
      case 'failed':
        status = PaymentStatus.failed;
        break;
      case 'refunded':
        status = PaymentStatus.refunded;
        break;
      default:
        status = PaymentStatus.pending;
    }

    return SubscriptionPaymentModel(
      id: json['id'] as String,
      subscriptionId: json['subscription_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      status: status,
      stripePaymentIntentId: json['stripe_payment_intent_id'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    String statusStr;
    switch (status) {
      case PaymentStatus.pending:
        statusStr = 'pending';
        break;
      case PaymentStatus.succeeded:
        statusStr = 'succeeded';
        break;
      case PaymentStatus.failed:
        statusStr = 'failed';
        break;
      case PaymentStatus.refunded:
        statusStr = 'refunded';
        break;
    }

    return {
      'id': id,
      'subscription_id': subscriptionId,
      'amount': amount,
      'currency': currency,
      'status': statusStr,
      'stripe_payment_intent_id': stripePaymentIntentId,
      'receipt_url': receiptUrl,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

