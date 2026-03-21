import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/food/domain/entities/restaurant.dart';
import 'package:mwanachuo/features/food/domain/entities/food_item.dart';
import 'package:mwanachuo/features/food/domain/entities/rider.dart';
import 'package:mwanachuo/features/food/domain/repositories/food_repository.dart';

part 'food_event.dart';
part 'food_state.dart';

class FoodBloc extends Bloc<FoodEvent, FoodState> {
  final FoodRepository repository;
  StreamSubscription? _trackingSubscription;

  FoodBloc({required this.repository}) : super(const FoodState()) {
    on<LoadRestaurants>(_onLoadRestaurants);
    on<LoadMenu>(_onLoadMenu);
    on<PlaceOrderEvent>(_onPlaceOrder);
    on<RegisterRestaurantEvent>(_onRegisterRestaurant);
    on<LoadTracking>(_onLoadTracking);
    on<UpdateTracking>(_onUpdateTracking);
  }

  @override
  Future<void> close() {
    _trackingSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadTracking(LoadTracking event, Emitter<FoodState> emit) async {
    emit(state.copyWith(status: FoodStatus.loading));
    
    // Initial fetch to get the current state immediately
    final result = await repository.getRiderForOrder(event.orderId);
    result.fold(
      (failure) => null, // Might not have a rider yet
      (rider) => emit(state.copyWith(status: FoodStatus.loaded, rider: rider)),
    );

    // Cancel existing and start new subscription
    await _trackingSubscription?.cancel();
    _trackingSubscription = repository.watchOrder(event.orderId).listen((orderData) {
      add(UpdateTracking(orderData));
    });
  }

  Future<void> _onUpdateTracking(UpdateTracking event, Emitter<FoodState> emit) async {
    final riderId = event.orderData['rider_id']?.toString();
    final orderStatus = event.orderData['status']?.toString();
    final trackingLink = event.orderData['tracking_link']?.toString();

    Rider? currentRider = state.rider;
    
    // If rider was just assigned or changed, fetch full details
    if (riderId != null && (currentRider == null || currentRider.id != riderId)) {
        final result = await repository.getRiderForOrder(event.orderData['id']);
        result.fold((_) => null, (rider) => currentRider = rider);
    }

    emit(state.copyWith(
      status: FoodStatus.loaded,
      rider: currentRider,
      orderStatus: orderStatus,
      trackingLink: trackingLink,
    ));
  }

  Future<void> _onLoadRestaurants(LoadRestaurants event, Emitter<FoodState> emit) async {
    emit(state.copyWith(status: FoodStatus.loading));
    final result = await repository.getRestaurants();
    result.fold(
      (failure) => emit(state.copyWith(status: FoodStatus.error, errorMessage: failure.message)),
      (restaurants) => emit(state.copyWith(status: FoodStatus.loaded, restaurants: restaurants)),
    );
  }

  Future<void> _onLoadMenu(LoadMenu event, Emitter<FoodState> emit) async {
    // When loading a menu, we want to KEEP the restaurants list.
    emit(state.copyWith(status: FoodStatus.loading));
    final result = await repository.getMenu(event.restaurantId);
    result.fold(
      (failure) => emit(state.copyWith(status: FoodStatus.error, errorMessage: failure.message)),
      (menu) => emit(state.copyWith(
        status: FoodStatus.loaded,
        menu: menu,
        restaurantId: event.restaurantId,
      )),
    );
  }

  Future<void> _onPlaceOrder(PlaceOrderEvent event, Emitter<FoodState> emit) async {
    emit(state.copyWith(status: FoodStatus.loading));
    final result = await repository.placeOrder(
      restaurantId: event.restaurantId,
      items: event.items,
      totalAmount: event.totalAmount,
      lat: event.lat,
      lng: event.lng,
    );
    result.fold(
      (failure) => emit(state.copyWith(status: FoodStatus.error, errorMessage: failure.message)),
      (_) => emit(state.copyWith(status: FoodStatus.success, orderSuccess: true)),
    );
  }

  Future<void> _onRegisterRestaurant(RegisterRestaurantEvent event, Emitter<FoodState> emit) async {
    emit(state.copyWith(status: FoodStatus.loading));
    final result = await repository.registerRestaurant(
      name: event.name,
      description: event.description,
      address: event.address,
      phone: event.phone,
      category: event.category,
    );
    result.fold(
      (failure) => emit(state.copyWith(status: FoodStatus.error, errorMessage: failure.message)),
      (_) => emit(state.copyWith(status: FoodStatus.success, registrationSuccess: true)),
    );
  }
}
