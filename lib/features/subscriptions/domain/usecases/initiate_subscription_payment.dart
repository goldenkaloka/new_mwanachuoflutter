import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/subscriptions/domain/repositories/subscription_repository.dart';

class InitiateSubscriptionPayment
    implements UseCase<String, InitiateSubscriptionPaymentParams> {
  final SubscriptionRepository repository;

  InitiateSubscriptionPayment(this.repository);

  @override
  Future<Either<Failure, String>> call(
    InitiateSubscriptionPaymentParams params,
  ) async {
    return await repository.initiateSubscriptionPayment(
      amount: params.amount,
      phone: params.phone,
      planId: params.planId,
      sellerId: params.sellerId,
    );
  }
}

class InitiateSubscriptionPaymentParams extends Equatable {
  final double amount;
  final String phone;
  final String planId;
  final String sellerId;

  const InitiateSubscriptionPaymentParams({
    required this.amount,
    required this.phone,
    required this.planId,
    required this.sellerId,
  });

  @override
  List<Object> get props => [amount, phone, planId, sellerId];
}
