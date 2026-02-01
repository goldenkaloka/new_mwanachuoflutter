import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
  final String userId;
  final double balance;
  final String currency;
  final DateTime updatedAt;

  const WalletEntity({
    required this.userId,
    required this.balance,
    required this.currency,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [userId, balance, currency, updatedAt];
}
