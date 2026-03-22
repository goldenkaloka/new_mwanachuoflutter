import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:mwanachuo/features/food/domain/entities/restaurant.dart';
import 'package:mwanachuo/features/food/domain/entities/food_item.dart';
import 'package:mwanachuo/features/food/domain/entities/rider.dart';
import 'package:mwanachuo/features/food/domain/entities/rider_job.dart';
import 'package:mwanachuo/features/food/domain/entities/food_order.dart';
import 'package:mwanachuo/features/food/domain/repositories/food_repository.dart';
import 'package:geolocator/geolocator.dart';

part 'food_event.dart';
part 'food_state.dart';

class FoodBloc extends Bloc<FoodEvent, FoodState> {
  final FoodRepository repository;
  StreamSubscription? _trackingSubscription;
  StreamSubscription? _riderJobsSubscription;

  FoodBloc({required this.repository}) : super(const FoodState()) {
    on<LoadRestaurants>(_onLoadRestaurants);
    on<CheckUserRestaurant>(_onCheckUserRestaurant);
    on<LoadMenu>(_onLoadMenu);
    on<PlaceOrderEvent>(_onPlaceOrder);
    on<RegisterRestaurantEvent>(_onRegisterRestaurant);
    on<LoadTracking>(_onLoadTracking);
    on<UpdateTracking>(_onUpdateTracking);
    on<ClearOrderSuccess>(_onClearOrderSuccess);
    on<LoadRestaurantOrders>(_onLoadRestaurantOrders);
    on<UpdateOrderStatusEvent>(_onUpdateOrderStatus);
    on<LoadUserUniversity>(_onLoadUserUniversity);
    // Rider handlers
    on<LoadRiderProfileEvent>(_onLoadRiderProfile);
    on<ToggleRiderOnlineEvent>(_onToggleRiderOnline);
    on<LoadRiderActiveJobEvent>(_onLoadRiderActiveJob);
    on<StreamRiderJobsEvent>(_onStreamRiderJobs);
    on<RiderJobsUpdatedEvent>(_onRiderJobsUpdated);
    on<AcceptJobEvent>(_onAcceptJob);
    on<DeclineJobEvent>(_onDeclineJob);
    on<UpdateRiderLocationEvent>(_onUpdateRiderLocation);
    on<UpdateOrderStatusAsRiderEvent>(_onUpdateOrderStatusAsRider);
    on<MarkDeliveredEvent>(_onMarkDelivered);
    on<DispatchRiderEvent>(_onDispatchRider);
  }

  @override
  Future<void> close() {
    _trackingSubscription?.cancel();
    _riderJobsSubscription?.cancel();
    return super.close();
  }

  // ─── Existing handlers ──────────────────────────────────────────────────────
  Future<void> _onLoadTracking(LoadTracking event, Emitter<FoodState> emit) async {
    emit(state.copyWith(status: FoodStatus.loading));
    
    // Fetch full order to get lat/lng coordinates
    final orderResult = await repository.getOrderDetails(event.orderId);
    orderResult.fold(
      (failure) => null,
      (order) => emit(state.copyWith(trackingOrder: order)),
    );

    // Fetch assigned rider
    final riderResult = await repository.getRiderForOrder(event.orderId);
    riderResult.fold(
      (failure) => null,
      (rider) => emit(state.copyWith(status: FoodStatus.loaded, rider: rider)),
    );
    
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
    double? userLat = event.userLat;
    double? userLng = event.userLng;

    if (userLat == null || userLng == null) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            Position position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
            );
            userLat = position.latitude;
            userLng = position.longitude;
          }
        }
      } catch (e) {
        // ignore
      }
    }

    final result = await repository.getRestaurants(userLat: userLat, userLng: userLng);
    result.fold(
      (failure) => emit(state.copyWith(status: FoodStatus.error, errorMessage: failure.message)),
      (restaurants) => emit(state.copyWith(
        status: FoodStatus.loaded,
        restaurants: restaurants,
        userLat: userLat,
        userLng: userLng,
      )),
    );
  }

  Future<void> _onLoadMenu(LoadMenu event, Emitter<FoodState> emit) async {
    emit(state.copyWith(status: FoodStatus.loading, orderSuccess: false));
    final result = await repository.getMenu(event.restaurantId);
    result.fold(
      (failure) => emit(state.copyWith(status: FoodStatus.error, errorMessage: failure.message)),
      (menu) => emit(state.copyWith(status: FoodStatus.loaded, menu: menu, restaurantId: event.restaurantId)),
    );
  }

  Future<void> _onPlaceOrder(PlaceOrderEvent event, Emitter<FoodState> emit) async {
    emit(state.copyWith(status: FoodStatus.loading, orderSuccess: false));
    final result = await repository.placeOrder(
      restaurantId: event.restaurantId,
      items: event.items,
      totalAmount: event.totalAmount,
      lat: event.lat,
      lng: event.lng,
      droppingPoint: event.droppingPoint,
      notes: event.notes,
      logisticsType: event.logisticsType,
    );
    result.fold(
      (failure) => emit(state.copyWith(status: FoodStatus.error, errorMessage: failure.message)),
      (orderId) => emit(state.copyWith(status: FoodStatus.loaded, orderSuccess: true, lastOrderId: orderId)),
    );
  }

  Future<void> _onRegisterRestaurant(RegisterRestaurantEvent event, Emitter<FoodState> emit) async {
    emit(state.copyWith(status: FoodStatus.loading));
    String? imageUrl;
    if (event.imageFile != null) {
      final uploadResult = await repository.uploadRestaurantImage(event.imageFile!);
      uploadResult.fold(
        (failure) => emit(state.copyWith(status: FoodStatus.error, errorMessage: failure.message)),
        (url) => imageUrl = url,
      );
      if (state.status == FoodStatus.error) return;
    }
    final result = await repository.registerRestaurant(
      name: event.name,
      description: event.description,
      address: event.address,
      phone: event.phone,
      category: event.category,
      imageUrl: imageUrl,
    );
    result.fold(
      (failure) => emit(state.copyWith(status: FoodStatus.error, errorMessage: failure.message)),
      (_) => emit(state.copyWith(status: FoodStatus.success, registrationSuccess: true)),
    );
  }

  Future<void> _onCheckUserRestaurant(CheckUserRestaurant event, Emitter<FoodState> emit) async {
    emit(state.copyWith(status: FoodStatus.loading));
    final result = await repository.getUserRestaurant();
    result.fold(
      (failure) => emit(state.copyWith(status: FoodStatus.error, errorMessage: failure.message)),
      (restaurant) => emit(state.copyWith(status: FoodStatus.loaded, userRestaurant: restaurant)),
    );
  }

  void _onClearOrderSuccess(ClearOrderSuccess event, Emitter<FoodState> emit) {
    emit(state.copyWith(orderSuccess: false));
  }

  Future<void> _onLoadRestaurantOrders(LoadRestaurantOrders event, Emitter<FoodState> emit) async {
    emit(state.copyWith(status: FoodStatus.loading));
    final result = await repository.getOrdersForRestaurant(event.restaurantId);
    result.fold(
      (failure) => emit(state.copyWith(status: FoodStatus.error, errorMessage: failure.message)),
      (orders) => emit(state.copyWith(status: FoodStatus.loaded, restaurantOrders: orders)),
    );
  }

  Future<void> _onUpdateOrderStatus(UpdateOrderStatusEvent event, Emitter<FoodState> emit) async {
    emit(state.copyWith(status: FoodStatus.loading));
    final result = await repository.updateOrderStatus(event.orderId, event.status, rejectionReason: event.rejectionReason);
    result.fold(
      (failure) => emit(state.copyWith(status: FoodStatus.error, errorMessage: failure.message)),
      (_) => add(LoadRestaurantOrders(event.restaurantId)),
    );
  }

  Future<void> _onLoadUserUniversity(LoadUserUniversity event, Emitter<FoodState> emit) async {
    final result = await repository.getUserUniversityId();
    result.fold(
      (failure) => null,
      (universityId) => emit(state.copyWith(userUniversityId: universityId)),
    );
  }

  // ─── Rider handlers ──────────────────────────────────────────────────────────
  Future<void> _onLoadRiderProfile(LoadRiderProfileEvent event, Emitter<FoodState> emit) async {
    emit(state.copyWith(status: FoodStatus.loading));
    final result = await repository.getCurrentRiderProfile();
    result.fold(
      (failure) => emit(state.copyWith(status: FoodStatus.error, errorMessage: failure.message)),
      (rider) => emit(state.copyWith(
        status: FoodStatus.loaded,
        riderProfile: rider,
        isRiderOnline: rider?.isOnline ?? false,
      )),
    );
  }

  Future<void> _onToggleRiderOnline(ToggleRiderOnlineEvent event, Emitter<FoodState> emit) async {
    // Optimistically update UI first
    emit(state.copyWith(isRiderOnline: event.isOnline));
    final result = await repository.toggleRiderOnline(event.isOnline);
    result.fold(
      (failure) {
        // Revert optimistic update on failure
        emit(state.copyWith(isRiderOnline: !event.isOnline, errorMessage: failure.message));
        debugPrint('Toggle rider online failed: ${failure.message}');
      },
      (_) => null,
    );
  }

  Future<void> _onLoadRiderActiveJob(LoadRiderActiveJobEvent event, Emitter<FoodState> emit) async {
    final result = await repository.getRiderActiveJob();
    result.fold(
      (failure) => null,
      (job) => emit(state.copyWith(activeJob: job, clearActiveJob: job == null)),
    );
  }

  void _onStreamRiderJobs(StreamRiderJobsEvent event, Emitter<FoodState> emit) {
    _riderJobsSubscription?.cancel();
    _riderJobsSubscription = repository.streamPendingJobs().listen((jobs) {
      add(RiderJobsUpdatedEvent(jobs));
    });
  }

  void _onRiderJobsUpdated(RiderJobsUpdatedEvent event, Emitter<FoodState> emit) {
    emit(state.copyWith(pendingJobs: event.jobs));
  }

  Future<void> _onAcceptJob(AcceptJobEvent event, Emitter<FoodState> emit) async {
    emit(state.copyWith(status: FoodStatus.loading));
    final result = await repository.acceptJob(event.orderId);
    result.fold(
      (failure) => emit(state.copyWith(status: FoodStatus.error, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(
          status: FoodStatus.loaded,
          jobAcceptSuccess: true,
          // Remove the accepted job from pending list
          pendingJobs: state.pendingJobs.where((j) => j.id != event.jobId).toList(),
        ));
        // Load the active job after accepting
        add(LoadRiderActiveJobEvent());
      },
    );
  }

  Future<void> _onDeclineJob(DeclineJobEvent event, Emitter<FoodState> emit) async {
    final result = await repository.declineJob(event.jobId);
    result.fold(
      (failure) => null,
      (_) => emit(state.copyWith(
        pendingJobs: state.pendingJobs.where((j) => j.id != event.jobId).toList(),
      )),
    );
  }

  Future<void> _onUpdateRiderLocation(UpdateRiderLocationEvent event, Emitter<FoodState> emit) async {
    await repository.updateRiderLocation(event.lat, event.lng);
  }

  Future<void> _onUpdateOrderStatusAsRider(UpdateOrderStatusAsRiderEvent event, Emitter<FoodState> emit) async {
    emit(state.copyWith(status: FoodStatus.loading));
    final result = await repository.updateOrderStatusAsRider(event.orderId, event.status);
    result.fold(
      (failure) => emit(state.copyWith(status: FoodStatus.error, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(status: FoodStatus.loaded));
        add(LoadRiderActiveJobEvent());
      },
    );
  }

  Future<void> _onMarkDelivered(MarkDeliveredEvent event, Emitter<FoodState> emit) async {
    emit(state.copyWith(status: FoodStatus.loading));
    final result = await repository.markDelivered(event.orderId, event.otp);
    result.fold(
      (failure) => emit(state.copyWith(status: FoodStatus.error, errorMessage: failure.message)),
      (_) => emit(state.copyWith(
        status: FoodStatus.success,
        deliverySuccess: true,
        clearActiveJob: true,
      )),
    );
  }

  Future<void> _onDispatchRider(DispatchRiderEvent event, Emitter<FoodState> emit) async {
    await repository.findAndAssignNearbyRider(event.order);
  }
}
