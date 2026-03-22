part of 'food_bloc.dart';

enum FoodStatus { initial, loading, loaded, error, success }

class FoodState extends Equatable {
  final List<Restaurant> restaurants;
  final List<FoodItem> menu;
  final String? restaurantId;
  final Rider? rider;
  final FoodOrder? trackingOrder;
  final String? orderStatus;
  final String? trackingLink;
  final String? lastOrderId;
  final FoodStatus status;
  final String? errorMessage;
  final bool orderSuccess;
  final bool registrationSuccess;
  final Restaurant? userRestaurant;
  final List<FoodOrder> restaurantOrders;
  final String? userUniversityId;
  final double? userLat;
  final double? userLng;
  // Rider-specific state
  final Rider? riderProfile;
  final bool isRiderOnline;
  final FoodOrder? activeJob;
  final List<RiderJob> pendingJobs;
  final bool jobAcceptSuccess;
  final bool deliverySuccess;

  const FoodState({
    this.restaurants = const [],
    this.menu = const [],
    this.restaurantId,
    this.rider,
    this.trackingOrder,
    this.orderStatus,
    this.trackingLink,
    this.lastOrderId,
    this.status = FoodStatus.initial,
    this.errorMessage,
    this.orderSuccess = false,
    this.registrationSuccess = false,
    this.userRestaurant,
    this.restaurantOrders = const [],
    this.userUniversityId,
    this.userLat,
    this.userLng,
    this.riderProfile,
    this.isRiderOnline = false,
    this.activeJob,
    this.pendingJobs = const [],
    this.jobAcceptSuccess = false,
    this.deliverySuccess = false,
  });

  FoodState copyWith({
    List<Restaurant>? restaurants,
    List<FoodItem>? menu,
    String? restaurantId,
    Rider? rider,
    FoodOrder? trackingOrder,
    String? orderStatus,
    String? trackingLink,
    String? lastOrderId,
    FoodStatus? status,
    String? errorMessage,
    bool? orderSuccess,
    bool? registrationSuccess,
    Restaurant? userRestaurant,
    List<FoodOrder>? restaurantOrders,
    String? userUniversityId,
    double? userLat,
    double? userLng,
    Rider? riderProfile,
    bool? isRiderOnline,
    FoodOrder? activeJob,
    bool clearActiveJob = false,
    List<RiderJob>? pendingJobs,
    bool? jobAcceptSuccess,
    bool? deliverySuccess,
  }) {
    return FoodState(
      restaurants: restaurants ?? this.restaurants,
      menu: menu ?? this.menu,
      restaurantId: restaurantId ?? this.restaurantId,
      rider: rider ?? this.rider,
      trackingOrder: trackingOrder ?? this.trackingOrder,
      orderStatus: orderStatus ?? this.orderStatus,
      trackingLink: trackingLink ?? this.trackingLink,
      lastOrderId: lastOrderId ?? this.lastOrderId,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      orderSuccess: orderSuccess ?? this.orderSuccess,
      registrationSuccess: registrationSuccess ?? this.registrationSuccess,
      userRestaurant: userRestaurant ?? this.userRestaurant,
      restaurantOrders: restaurantOrders ?? this.restaurantOrders,
      userUniversityId: userUniversityId ?? this.userUniversityId,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
      riderProfile: riderProfile ?? this.riderProfile,
      isRiderOnline: isRiderOnline ?? this.isRiderOnline,
      activeJob: clearActiveJob ? null : (activeJob ?? this.activeJob),
      pendingJobs: pendingJobs ?? this.pendingJobs,
      jobAcceptSuccess: jobAcceptSuccess ?? this.jobAcceptSuccess,
      deliverySuccess: deliverySuccess ?? this.deliverySuccess,
    );
  }

  @override
  List<Object?> get props => [
    restaurants, menu, restaurantId, rider, trackingOrder, orderStatus, trackingLink,
    lastOrderId, status, errorMessage, orderSuccess, registrationSuccess,
    userRestaurant, restaurantOrders, userUniversityId, userLat, userLng,
    riderProfile, isRiderOnline, activeJob, pendingJobs, jobAcceptSuccess, deliverySuccess,
  ];
}
