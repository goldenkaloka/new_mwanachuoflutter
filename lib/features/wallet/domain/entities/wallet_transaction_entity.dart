import 'package:equatable/equatable.dart';

enum WalletTransactionType { deposit, fee, payment, refund }

class WalletTransactionEntity extends Equatable {
  final String id;
  final String walletId;
  final double amount;
  final WalletTransactionType type;
  final String? referenceId;
  final String? description;
  final DateTime createdAt;

  const WalletTransactionEntity({
    required this.id,
    required this.walletId,
    required this.amount,
    required this.type,
    this.referenceId,
    this.description,
    required this.createdAt,
  });

  bool get isCredit => amount >= 0;

  @override
  List<Object?> get props => [
    id,
    walletId,
    amount,
    type,
    referenceId,
    description,
    createdAt,
  ];
}
