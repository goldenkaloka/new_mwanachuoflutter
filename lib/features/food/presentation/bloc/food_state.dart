part of 'food_bloc.dart';

enum FoodStatus { initial, loading, loaded, error, success }

class FoodState extends Equatable {
  final List<Restaurant> restaurants;
  final List<FoodItem> menu;
  final String? restaurantId;
  final Rider? rider;
  final String? orderStatus;
  final String? trackingLink;
  final FoodStatus status;
  final String? errorMessage;
  final bool orderSuccess;
  final bool registrationSuccess;

  const FoodState({
    this.restaurants = const [],
    this.menu = const [],
    this.restaurantId,
    this.rider,
    this.orderStatus,
    this.trackingLink,
    this.status = FoodStatus.initial,
    this.errorMessage,
    this.orderSuccess = false,
    this.registrationSuccess = false,
  });

  FoodState copyWith({
    List<Restaurant>? restaurants,
    List<FoodItem>? menu,
    String? restaurantId,
    Rider? rider,
    String? orderStatus,
    String? trackingLink,
    FoodStatus? status,
    String? errorMessage,
    bool? orderSuccess,
    bool? registrationSuccess,
  }) {
    return FoodState(
      restaurants: restaurants ?? this.restaurants,
      menu: menu ?? this.menu,
      restaurantId: restaurantId ?? this.restaurantId,
      rider: rider ?? this.rider,
      orderStatus: orderStatus ?? this.orderStatus,
      trackingLink: trackingLink ?? this.trackingLink,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      orderSuccess: orderSuccess ?? this.orderSuccess,
      registrationSuccess: registrationSuccess ?? this.registrationSuccess,
    );
  }

  @override
  List<Object?> get props => [
        restaurants,
        menu,
        restaurantId,
        rider,
        orderStatus,
        trackingLink,
        status,
        errorMessage,
        orderSuccess,
        registrationSuccess,
      ];
}
