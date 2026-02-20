import 'package:mwanachuo/features/wallet/domain/entities/manual_payment_request_entity.dart';

class ManualPaymentRequestModel extends ManualPaymentRequestEntity {
  const ManualPaymentRequestModel({
    required super.id,
    required super.userId,
    required super.amount,
    required super.transactionRef,
    super.payerPhone,
    required super.type,
    required super.status,
    super.adminNote,
    super.metadata,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ManualPaymentRequestModel.fromJson(Map<String, dynamic> json) {
    return ManualPaymentRequestModel(
      id: json['id'],
      userId: json['user_id'],
      amount: (json['amount'] as num).toDouble(),
      transactionRef: json['transaction_ref'],
      payerPhone: json['payer_phone'],
      type: _parseType(json['type']),
      status: _parseStatus(json['status']),
      adminNote: json['admin_note'],
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'transaction_ref': transactionRef,
      'payer_phone': payerPhone,
      'type': type.name,
      'status': status.name,
      'admin_note': adminNote,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static PaymentRequestType _parseType(String type) {
    return PaymentRequestType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => PaymentRequestType.topup,
    );
  }

  static PaymentRequestStatus _parseStatus(String status) {
    return PaymentRequestStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => PaymentRequestStatus.pending,
    );
  }
}
