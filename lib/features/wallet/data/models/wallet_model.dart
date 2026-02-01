import 'package:mwanachuo/features/wallet/domain/entities/wallet_entity.dart';

class WalletModel extends WalletEntity {
  const WalletModel({
    required super.userId,
    required super.balance,
    required super.currency,
    required super.updatedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      userId: json['user_id'],
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] ?? 'TZS',
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
