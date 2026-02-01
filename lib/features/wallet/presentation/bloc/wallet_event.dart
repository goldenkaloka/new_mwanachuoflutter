part of 'wallet_bloc.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object> get props => [];
}

class LoadWalletData extends WalletEvent {}

class InitiateWalletTopUp extends WalletEvent {
  final double amount;
  final String phone;
  final String provider;

  const InitiateWalletTopUp({
    required this.amount,
    required this.phone,
    required this.provider,
  });

  @override
  List<Object> get props => [amount, phone, provider];
}
