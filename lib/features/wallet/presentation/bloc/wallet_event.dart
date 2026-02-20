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

class LoadManualPaymentRequests extends WalletEvent {}

class LoadPendingManualPaymentRequests extends WalletEvent {}

class SubmitPaymentProofEvent extends WalletEvent {
  final double amount;
  final String transactionRef;
  final String payerPhone;
  final String type;
  final Map<String, dynamic>? metadata;

  const SubmitPaymentProofEvent({
    required this.amount,
    required this.transactionRef,
    required this.payerPhone,
    required this.type,
    this.metadata,
  });

  @override
  List<Object> get props => [
    amount,
    transactionRef,
    payerPhone,
    type,
    metadata ?? {},
  ];
}

class ApproveManualPaymentEvent extends WalletEvent {
  final String requestId;
  final String? adminNote;

  const ApproveManualPaymentEvent({required this.requestId, this.adminNote});

  @override
  List<Object> get props => [requestId, adminNote ?? ''];
}

class RejectManualPaymentEvent extends WalletEvent {
  final String requestId;
  final String? adminNote;

  const RejectManualPaymentEvent({required this.requestId, this.adminNote});

  @override
  List<Object> get props => [requestId, adminNote ?? ''];
}
