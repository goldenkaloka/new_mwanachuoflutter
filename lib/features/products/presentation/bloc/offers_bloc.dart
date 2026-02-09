import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/products/domain/entities/product_offer.dart';
import 'package:mwanachuo/features/products/domain/repositories/product_cart_repository.dart';

// ==================== EVENTS ====================

abstract class OffersEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CreateOffer extends OffersEvent {
  final String productId;
  final String sellerId;
  final String conversationId;
  final double offerAmount;
  final double originalPrice;
  final String? message;

  CreateOffer({
    required this.productId,
    required this.sellerId,
    required this.conversationId,
    required this.offerAmount,
    required this.originalPrice,
    this.message,
  });

  @override
  List<Object?> get props => [
    productId,
    sellerId,
    conversationId,
    offerAmount,
    originalPrice,
    message,
  ];
}

class AcceptOffer extends OffersEvent {
  final String offerId;

  AcceptOffer(this.offerId);

  @override
  List<Object?> get props => [offerId];
}

class DeclineOffer extends OffersEvent {
  final String offerId;

  DeclineOffer(this.offerId);

  @override
  List<Object?> get props => [offerId];
}

class CounterOffer extends OffersEvent {
  final String offerId;
  final double counterAmount;
  final String? message;

  CounterOffer({
    required this.offerId,
    required this.counterAmount,
    this.message,
  });

  @override
  List<Object?> get props => [offerId, counterAmount, message];
}

class LoadOfferHistory extends OffersEvent {
  final String offerId;

  LoadOfferHistory(this.offerId);

  @override
  List<Object?> get props => [offerId];
}

class LoadProductOffers extends OffersEvent {
  final String productId;
  final OfferStatus? status;

  LoadProductOffers({required this.productId, this.status});

  @override
  List<Object?> get props => [productId, status];
}

// ==================== STATES ====================

abstract class OffersState extends Equatable {
  @override
  List<Object?> get props => [];
}

class OffersInitial extends OffersState {}

class OffersLoading extends OffersState {}

class OfferCreated extends OffersState {
  final ProductOffer offer;

  OfferCreated(this.offer);

  @override
  List<Object?> get props => [offer];
}

class OfferAccepted extends OffersState {
  final ProductOffer offer;

  OfferAccepted(this.offer);

  @override
  List<Object?> get props => [offer];
}

class OfferDeclined extends OffersState {
  final ProductOffer offer;

  OfferDeclined(this.offer);

  @override
  List<Object?> get props => [offer];
}

class OfferCountered extends OffersState {
  final ProductOffer offer;

  OfferCountered(this.offer);

  @override
  List<Object?> get props => [offer];
}

class OffersLoaded extends OffersState {
  final List<ProductOffer> offers;

  OffersLoaded(this.offers);

  @override
  List<Object?> get props => [offers];
}

class OfferHistoryLoaded extends OffersState {
  final List<OfferHistoryItem> history;

  OfferHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

class OffersError extends OffersState {
  final String message;

  OffersError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== BLOC ====================

class OffersBloc extends Bloc<OffersEvent, OffersState> {
  final ProductCartRepository repository;

  OffersBloc({required this.repository}) : super(OffersInitial()) {
    on<CreateOffer>(_onCreateOffer);
    on<AcceptOffer>(_onAcceptOffer);
    on<DeclineOffer>(_onDeclineOffer);
    on<CounterOffer>(_onCounterOffer);
    on<LoadOfferHistory>(_onLoadOfferHistory);
    on<LoadProductOffers>(_onLoadProductOffers);
  }

  Future<void> _onCreateOffer(
    CreateOffer event,
    Emitter<OffersState> emit,
  ) async {
    emit(OffersLoading());

    final result = await repository.createOffer(
      productId: event.productId,
      sellerId: event.sellerId,
      conversationId: event.conversationId,
      offerAmount: event.offerAmount,
      originalPrice: event.originalPrice,
      message: event.message,
    );

    result.fold(
      (failure) => emit(OffersError(failure.message)),
      (offer) => emit(OfferCreated(offer)),
    );
  }

  Future<void> _onAcceptOffer(
    AcceptOffer event,
    Emitter<OffersState> emit,
  ) async {
    emit(OffersLoading());

    final result = await repository.acceptOffer(event.offerId);

    result.fold(
      (failure) => emit(OffersError(failure.message)),
      (offer) => emit(OfferAccepted(offer)),
    );
  }

  Future<void> _onDeclineOffer(
    DeclineOffer event,
    Emitter<OffersState> emit,
  ) async {
    emit(OffersLoading());

    final result = await repository.declineOffer(event.offerId);

    result.fold(
      (failure) => emit(OffersError(failure.message)),
      (offer) => emit(OfferDeclined(offer)),
    );
  }

  Future<void> _onCounterOffer(
    CounterOffer event,
    Emitter<OffersState> emit,
  ) async {
    emit(OffersLoading());

    final result = await repository.counterOffer(
      offerId: event.offerId,
      counterAmount: event.counterAmount,
      message: event.message,
    );

    result.fold(
      (failure) => emit(OffersError(failure.message)),
      (offer) => emit(OfferCountered(offer)),
    );
  }

  Future<void> _onLoadOfferHistory(
    LoadOfferHistory event,
    Emitter<OffersState> emit,
  ) async {
    emit(OffersLoading());

    final result = await repository.getOfferHistory(event.offerId);

    result.fold(
      (failure) => emit(OffersError(failure.message)),
      (history) => emit(OfferHistoryLoaded(history)),
    );
  }

  Future<void> _onLoadProductOffers(
    LoadProductOffers event,
    Emitter<OffersState> emit,
  ) async {
    emit(OffersLoading());

    final result = await repository.getProductOffers(
      productId: event.productId,
      status: event.status,
    );

    result.fold(
      (failure) => emit(OffersError(failure.message)),
      (offers) => emit(OffersLoaded(offers)),
    );
  }
}
