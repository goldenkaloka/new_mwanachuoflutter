import 'package:mwanachuo/features/wallet/domain/entities/wallet_transaction_entity.dart';

class WalletTransactionModel extends WalletTransactionEntity {
  const WalletTransactionModel({
    required super.id,
    required super.walletId,
    required super.amount,
    required super.type,
    super.referenceId,
    super.description,
    required super.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'],
      walletId: json['wallet_id'],
      amount: (json['amount'] as num).toDouble(),
      type: _parseType(json['type']),
      referenceId: json['reference_id'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static WalletTransactionType _parseType(String type) {
    switch (type) {
      case 'deposit':
        return WalletTransactionType.deposit;
      case 'fee':
        return WalletTransactionType.fee;
      case 'payment':
        return WalletTransactionType.payment;
      case 'refund':
        return WalletTransactionType.refund;
      default:
        return WalletTransactionType.payment; // Default fallback
    }
  }
}
