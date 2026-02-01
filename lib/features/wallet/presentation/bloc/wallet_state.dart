part of 'wallet_bloc.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object> get props => [];
}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  final WalletEntity wallet;
  final List<WalletTransactionEntity> transactions;

  const WalletLoaded({required this.wallet, required this.transactions});

  @override
  List<Object> get props => [wallet, transactions];
}

class WalletError extends WalletState {
  final String message;

  const WalletError(this.message);

  @override
  List<Object> get props => [message];
}

class WalletTopUpInitiated extends WalletState {
  final String orderId;
  final WalletEntity wallet;
  final List<WalletTransactionEntity> transactions;

  const WalletTopUpInitiated({
    required this.orderId,
    required this.wallet,
    required this.transactions,
  });

  @override
  List<Object> get props => [orderId, wallet, transactions];
}

class WalletTopUpFailure extends WalletState {
  final String message;
  final WalletEntity wallet;
  final List<WalletTransactionEntity> transactions;

  const WalletTopUpFailure({
    required this.message,
    required this.wallet,
    required this.transactions,
  });

  @override
  List<Object> get props => [message, wallet, transactions];
}
