import 'package:equatable/equatable.dart';

enum PaymentRequestStatus { pending, approved, rejected }

enum PaymentRequestType { topup, subscription, promotion }

class ManualPaymentRequestEntity extends Equatable {
  final String id;
  final String userId;
  final double amount;
  final String transactionRef;
  final String? payerPhone;
  final PaymentRequestType type;
  final PaymentRequestStatus status;
  final String? adminNote;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ManualPaymentRequestEntity({
    required this.id,
    required this.userId,
    required this.amount,
    required this.transactionRef,
    this.payerPhone,
    required this.type,
    required this.status,
    this.adminNote,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    amount,
    transactionRef,
    payerPhone,
    type,
    status,
    adminNote,
    metadata,
    createdAt,
    updatedAt,
  ];
}
