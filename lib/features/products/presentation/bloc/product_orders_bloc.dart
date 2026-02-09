import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/products/domain/entities/product_order.dart';
import 'package:mwanachuo/features/products/domain/repositories/product_cart_repository.dart';

// ==================== EVENTS ====================

abstract class ProductOrdersEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class PlaceProductOrder extends ProductOrdersEvent {
  final String sellerId;
  final List<ProductOrderItem> items;
  final PaymentMethod paymentMethod;
  final DeliveryMethod deliveryMethod;
  final String? deliverySpotId;
  final String? deliveryAddress;
  final String? deliveryPhone;
  final String? conversationId;
  final String? offerId;
  final double? agreedPrice;

  PlaceProductOrder({
    required this.sellerId,
    required this.items,
    required this.paymentMethod,
    required this.deliveryMethod,
    this.deliverySpotId,
    this.deliveryAddress,
    this.deliveryPhone,
    this.conversationId,
    this.offerId,
    this.agreedPrice,
  });

  @override
  List<Object?> get props => [
    sellerId,
    items,
    paymentMethod,
    deliveryMethod,
    deliverySpotId,
    deliveryAddress,
    deliveryPhone,
    conversationId,
    offerId,
    agreedPrice,
  ];
}

class FetchMyProductOrders extends ProductOrdersEvent {
  final ProductOrderStatus? status;

  FetchMyProductOrders({this.status});

  @override
  List<Object?> get props => [status];
}

class FetchSellerOrders extends ProductOrdersEvent {
  final ProductOrderStatus? status;

  FetchSellerOrders({this.status});

  @override
  List<Object?> get props => [status];
}

class UpdateOrderStatus extends ProductOrdersEvent {
  final String orderId;
  final ProductOrderStatus status;
  final String? trackingNotes;

  UpdateOrderStatus({
    required this.orderId,
    required this.status,
    this.trackingNotes,
  });

  @override
  List<Object?> get props => [orderId, status, trackingNotes];
}

class CancelProductOrder extends ProductOrdersEvent {
  final String orderId;

  CancelProductOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

// ==================== STATES ====================

abstract class ProductOrdersState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductOrdersInitial extends ProductOrdersState {}

class ProductOrdersLoading extends ProductOrdersState {}

class ProductOrdersLoaded extends ProductOrdersState {
  final List<ProductOrder> orders;

  ProductOrdersLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class ProductOrderPlaced extends ProductOrdersState {
  final ProductOrder order;

  ProductOrderPlaced(this.order);

  @override
  List<Object?> get props => [order];
}

class ProductOrderStatusUpdated extends ProductOrdersState {
  final ProductOrder order;

  ProductOrderStatusUpdated(this.order);

  @override
  List<Object?> get props => [order];
}

class ProductOrdersError extends ProductOrdersState {
  final String message;

  ProductOrdersError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== BLOC ====================

class ProductOrdersBloc extends Bloc<ProductOrdersEvent, ProductOrdersState> {
  final ProductCartRepository repository;

  ProductOrdersBloc({required this.repository})
    : super(ProductOrdersInitial()) {
    on<PlaceProductOrder>(_onPlaceOrder);
    on<FetchMyProductOrders>(_onFetchMyOrders);
    on<FetchSellerOrders>(_onFetchSellerOrders);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<CancelProductOrder>(_onCancelOrder);
  }

  Future<void> _onPlaceOrder(
    PlaceProductOrder event,
    Emitter<ProductOrdersState> emit,
  ) async {
    emit(ProductOrdersLoading());

    final result = await repository.createOrder(
      sellerId: event.sellerId,
      items: event.items,
      paymentMethod: event.paymentMethod,
      deliveryMethod: event.deliveryMethod,
      deliverySpotId: event.deliverySpotId,
      deliveryAddress: event.deliveryAddress,
      deliveryPhone: event.deliveryPhone,
      conversationId: event.conversationId,
      offerId: event.offerId,
      agreedPrice: event.agreedPrice,
    );

    result.fold(
      (failure) => emit(ProductOrdersError(failure.message)),
      (order) => emit(ProductOrderPlaced(order)),
    );
  }

  Future<void> _onFetchMyOrders(
    FetchMyProductOrders event,
    Emitter<ProductOrdersState> emit,
  ) async {
    emit(ProductOrdersLoading());

    final result = await repository.getMyOrders(status: event.status);

    result.fold(
      (failure) => emit(ProductOrdersError(failure.message)),
      (orders) => emit(ProductOrdersLoaded(orders)),
    );
  }

  Future<void> _onFetchSellerOrders(
    FetchSellerOrders event,
    Emitter<ProductOrdersState> emit,
  ) async {
    emit(ProductOrdersLoading());

    final result = await repository.getSellerOrders(status: event.status);

    result.fold(
      (failure) => emit(ProductOrdersError(failure.message)),
      (orders) => emit(ProductOrdersLoaded(orders)),
    );
  }

  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatus event,
    Emitter<ProductOrdersState> emit,
  ) async {
    final result = await repository.updateOrderStatus(
      orderId: event.orderId,
      status: event.status,
      trackingNotes: event.trackingNotes,
    );

    result.fold(
      (failure) => emit(ProductOrdersError(failure.message)),
      (order) => emit(ProductOrderStatusUpdated(order)),
    );
  }

  Future<void> _onCancelOrder(
    CancelProductOrder event,
    Emitter<ProductOrdersState> emit,
  ) async {
    final result = await repository.cancelOrder(event.orderId);

    result.fold((failure) => emit(ProductOrdersError(failure.message)), (_) {
      // Refresh orders after cancellation
      add(FetchMyProductOrders());
    });
  }
}
