part of 'food_bloc.dart';

abstract class FoodEvent extends Equatable {
  const FoodEvent();

  @override
  List<Object?> get props => [];
}

class LoadRestaurants extends FoodEvent {}

class LoadMenu extends FoodEvent {
  final String restaurantId;
  const LoadMenu(this.restaurantId);

  @override
  List<Object?> get props => [restaurantId];
}

class PlaceOrderEvent extends FoodEvent {
  final String restaurantId;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final double lat;
  final double lng;

  const PlaceOrderEvent({
    required this.restaurantId,
    required this.items,
    required this.totalAmount,
    required this.lat,
    required this.lng,
  });

  @override
  List<Object?> get props => [restaurantId, items, totalAmount, lat, lng];
}

class RegisterRestaurantEvent extends FoodEvent {
  final String name;
  final String description;
  final String address;
  final String phone;
  final String category;

  const RegisterRestaurantEvent({
    required this.name,
    required this.description,
    required this.address,
    required this.phone,
    required this.category,
  });

  @override
  List<Object?> get props => [name, description, address, phone, category];
}

class LoadTracking extends FoodEvent {
  final String orderId;
  const LoadTracking(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class UpdateTracking extends FoodEvent {
  final Map<String, dynamic> orderData;
  const UpdateTracking(this.orderData);

  @override
  List<Object?> get props => [orderData];
}
