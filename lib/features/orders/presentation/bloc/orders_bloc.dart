import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/orders/domain/entities/order.dart';
import 'package:mwanachuo/features/orders/domain/entities/campus_spot.dart';
import 'package:mwanachuo/features/orders/domain/repositories/orders_repository.dart';

// Events
abstract class OrdersEvent extends Equatable {
  const OrdersEvent();
  @override
  List<Object?> get props => [];
}

class PlaceOrder extends OrdersEvent {
  final Order order;
  const PlaceOrder(this.order);
  @override
  List<Object?> get props => [order];
}

class FetchMyOrders extends OrdersEvent {}

class FetchAvailableJobs extends OrdersEvent {}

class FetchRunnerActiveOrders extends OrdersEvent {}

class FetchVendorOrders extends OrdersEvent {}

class UpdateOrder extends OrdersEvent {
  final String orderId;
  final OrderStatus status;
  const UpdateOrder(this.orderId, this.status);
  @override
  List<Object?> get props => [orderId, status];
}

class ClaimOrder extends OrdersEvent {
  final String orderId;
  const ClaimOrder(this.orderId);
  @override
  List<Object?> get props => [orderId];
}

class LoadCampusSpots extends OrdersEvent {
  final String? universityId;
  const LoadCampusSpots({this.universityId});
  @override
  List<Object?> get props => [universityId];
}

// State
abstract class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrderPlacedSuccess extends OrdersState {
  final Order order;
  const OrderPlacedSuccess(this.order);
  @override
  List<Object?> get props => [order];
}

class OrdersLoaded extends OrdersState {
  final List<Order> orders; // Buyer
  final List<Order> availableJobs; // Runner
  final List<Order> activeRunnerOrders; // Runner
  final List<Order> vendorOrders; // Vendor

  const OrdersLoaded({
    this.orders = const [],
    this.availableJobs = const [],
    this.activeRunnerOrders = const [],
    this.vendorOrders = const [],
  });

  OrdersLoaded copyWith({
    List<Order>? orders,
    List<Order>? availableJobs,
    List<Order>? activeRunnerOrders,
    List<Order>? vendorOrders,
  }) {
    return OrdersLoaded(
      orders: orders ?? this.orders,
      availableJobs: availableJobs ?? this.availableJobs,
      activeRunnerOrders: activeRunnerOrders ?? this.activeRunnerOrders,
      vendorOrders: vendorOrders ?? this.vendorOrders,
    );
  }

  @override
  List<Object?> get props => [
    orders,
    availableJobs,
    activeRunnerOrders,
    vendorOrders,
  ];
}

class OrdersFailure extends OrdersState {
  final String message;
  const OrdersFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class CampusSpotsLoaded extends OrdersState {
  final List<CampusSpot> spots;
  const CampusSpotsLoaded(this.spots);
  @override
  List<Object?> get props => [spots];
}

// Bloc
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrdersRepository repository;

  OrdersBloc({required this.repository}) : super(OrdersInitial()) {
    on<PlaceOrder>(_onPlaceOrder);
    on<FetchMyOrders>(_onFetchMyOrders);
    on<FetchAvailableJobs>(_onFetchAvailableJobs);
    on<FetchRunnerActiveOrders>(_onFetchRunnerActiveOrders);
    on<FetchVendorOrders>(_onFetchVendorOrders);
    on<UpdateOrder>(_onUpdateOrder);
    on<ClaimOrder>(_onClaimOrder);
    on<LoadCampusSpots>(_onLoadCampusSpots);
  }

  Future<void> _onPlaceOrder(
    PlaceOrder event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    final result = await repository.createOrder(event.order);
    result.fold(
      (failure) => emit(OrdersFailure(failure.message)),
      (order) => emit(OrderPlacedSuccess(order)),
    );
  }

  Future<void> _onFetchMyOrders(
    FetchMyOrders event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    final result = await repository.getOrders();
    result.fold(
      (failure) => emit(OrdersFailure(failure.message)),
      (orders) => emit(OrdersLoaded(orders: orders)),
    );
  }

  Future<void> _onFetchAvailableJobs(
    FetchAvailableJobs event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    final result = await repository.getAvailableRunnerJobs();
    result.fold(
      (failure) => emit(OrdersFailure(failure.message)),
      (jobs) => emit(OrdersLoaded(availableJobs: jobs)),
    );
  }

  Future<void> _onFetchRunnerActiveOrders(
    FetchRunnerActiveOrders event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    final result = await repository.getRunnerOrders();
    result.fold(
      (failure) => emit(OrdersFailure(failure.message)),
      (orders) => emit(OrdersLoaded(activeRunnerOrders: orders)),
    );
  }

  Future<void> _onFetchVendorOrders(
    FetchVendorOrders event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    final result = await repository.getVendorOrders();
    result.fold(
      (failure) => emit(OrdersFailure(failure.message)),
      (orders) => emit(OrdersLoaded(vendorOrders: orders)),
    );
  }

  Future<void> _onUpdateOrder(
    UpdateOrder event,
    Emitter<OrdersState> emit,
  ) async {
    final result = await repository.updateOrderStatus(
      event.orderId,
      event.status,
    );
    result.fold((failure) => emit(OrdersFailure(failure.message)), (_) {
      add(FetchMyOrders());
      add(FetchRunnerActiveOrders());
      add(FetchVendorOrders());
      add(FetchAvailableJobs());
    });
  }

  Future<void> _onClaimOrder(
    ClaimOrder event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    final result = await repository.claimOrder(event.orderId);
    result.fold((failure) => emit(OrdersFailure(failure.message)), (_) {
      add(FetchAvailableJobs());
      add(FetchRunnerActiveOrders());
    });
  }

  Future<void> _onLoadCampusSpots(
    LoadCampusSpots event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    final result = await repository.getCampusSpots(event.universityId);
    result.fold(
      (failure) => emit(OrdersFailure(failure.message)),
      (spots) => emit(CampusSpotsLoaded(spots)),
    );
  }
}
