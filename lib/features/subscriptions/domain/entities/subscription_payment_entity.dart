import 'package:equatable/equatable.dart';

enum PaymentStatus {
  pending,
  succeeded,
  failed,
  refunded,
}

class SubscriptionPaymentEntity extends Equatable {
  final String id;
  final String subscriptionId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String? stripePaymentIntentId;
  final String? receiptUrl;
  final DateTime? paidAt;
  final DateTime createdAt;

  const SubscriptionPaymentEntity({
    required this.id,
    required this.subscriptionId,
    required this.amount,
    this.currency = 'USD',
    required this.status,
    this.stripePaymentIntentId,
    this.receiptUrl,
    this.paidAt,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        subscriptionId,
        amount,
        currency,
        status,
        stripePaymentIntentId,
        receiptUrl,
        paidAt,
        createdAt,
      ];
}

