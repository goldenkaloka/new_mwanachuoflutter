part of 'food_bloc.dart';

abstract class FoodEvent extends Equatable {
  const FoodEvent();

  @override
  List<Object?> get props => [];
}

class LoadRestaurants extends FoodEvent {
  final double? userLat;
  final double? userLng;

  const LoadRestaurants({this.userLat, this.userLng});

  @override
  List<Object?> get props => [userLat, userLng];
}

class CheckUserRestaurant extends FoodEvent {}

class LoadSellersEvent extends FoodEvent {}

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
  final String? droppingPoint;
  final String? notes;
  final String logisticsType;

  const PlaceOrderEvent({
    required this.restaurantId,
    required this.items,
    required this.totalAmount,
    required this.lat,
    required this.lng,
    this.droppingPoint,
    this.notes,
    required this.logisticsType,
  });

  @override
  List<Object?> get props => [restaurantId, items, totalAmount, lat, lng, droppingPoint, notes, logisticsType];
}

class RegisterRestaurantEvent extends FoodEvent {
  final String name;
  final String description;
  final String address;
  final String phone;
  final String category;
  final Object? imageFile;
  final String? ownerId;
  final double? lat;
  final double? lng;

  const RegisterRestaurantEvent({
    required this.name,
    required this.description,
    required this.address,
    required this.phone,
    required this.category,
    this.imageFile,
    this.ownerId,
    this.lat,
    this.lng,
  });

  @override
  List<Object?> get props => [name, description, address, phone, category, imageFile, ownerId, lat, lng];
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

class ClearOrderSuccess extends FoodEvent {}

class LoadRestaurantOrders extends FoodEvent {
  final String restaurantId;
  const LoadRestaurantOrders(this.restaurantId);

  @override
  List<Object?> get props => [restaurantId];
}

class UpdateOrderStatusEvent extends FoodEvent {
  final String orderId;
  final FoodOrderStatus status;
  final String? rejectionReason;
  final String restaurantId;

  const UpdateOrderStatusEvent({
    required this.orderId,
    required this.status,
    this.rejectionReason,
    required this.restaurantId,
  });

  @override
  List<Object?> get props => [orderId, status, rejectionReason, restaurantId];
}

class LoadUserUniversity extends FoodEvent {}

// ─── Rider Events ────────────────────────────────────────────────────────────
class LoadRiderProfileEvent extends FoodEvent {}

class ToggleRiderOnlineEvent extends FoodEvent {
  final bool isOnline;
  const ToggleRiderOnlineEvent(this.isOnline);
  @override
  List<Object?> get props => [isOnline];
}

class LoadRiderActiveJobEvent extends FoodEvent {}

class StreamRiderJobsEvent extends FoodEvent {}

class RiderJobsUpdatedEvent extends FoodEvent {
  final List<RiderJob> jobs;
  const RiderJobsUpdatedEvent(this.jobs);
  @override
  List<Object?> get props => [jobs];
}

class AcceptJobEvent extends FoodEvent {
  final String orderId;
  final String jobId;
  const AcceptJobEvent({required this.orderId, required this.jobId});
  @override
  List<Object?> get props => [orderId, jobId];
}

class DeclineJobEvent extends FoodEvent {
  final String jobId;
  const DeclineJobEvent(this.jobId);
  @override
  List<Object?> get props => [jobId];
}

class UpdateRiderLocationEvent extends FoodEvent {
  final double lat;
  final double lng;
  const UpdateRiderLocationEvent({required this.lat, required this.lng});
  @override
  List<Object?> get props => [lat, lng];
}

class UpdateOrderStatusAsRiderEvent extends FoodEvent {
  final String orderId;
  final FoodOrderStatus status;
  const UpdateOrderStatusAsRiderEvent({required this.orderId, required this.status});
  @override
  List<Object?> get props => [orderId, status];
}

class MarkDeliveredEvent extends FoodEvent {
  final String orderId;
  final String otp;
  const MarkDeliveredEvent({required this.orderId, required this.otp});
  @override
  List<Object?> get props => [orderId, otp];
}

class DispatchRiderEvent extends FoodEvent {
  final FoodOrder order;
  const DispatchRiderEvent(this.order);
  @override
  List<Object?> get props => [order];
}

// ─── Menu Management Events ──────────────────────────────────────────────────
class AddFoodItemEvent extends FoodEvent {
  final FoodItem item;
  final Object? imageFile;
  const AddFoodItemEvent(this.item, {this.imageFile});
  @override
  List<Object?> get props => [item, imageFile];
}

class UpdateFoodItemEvent extends FoodEvent {
  final FoodItem item;
  final Object? imageFile;
  const UpdateFoodItemEvent(this.item, {this.imageFile});
  @override
  List<Object?> get props => [item, imageFile];
}

class DeleteFoodItemEvent extends FoodEvent {
  final String itemId;
  final String restaurantId;
  const DeleteFoodItemEvent(this.itemId, this.restaurantId);
  @override
  List<Object?> get props => [itemId, restaurantId];
}

class AddFoodAdditiveEvent extends FoodEvent {
  final FoodAdditive additive;
  final String restaurantId;
  const AddFoodAdditiveEvent(this.additive, this.restaurantId);
  @override
  List<Object?> get props => [additive, restaurantId];
}

class DeleteFoodAdditiveEvent extends FoodEvent {
  final String additiveId;
  final String restaurantId;
  const DeleteFoodAdditiveEvent(this.additiveId, this.restaurantId);
  @override
  List<Object?> get props => [additiveId, restaurantId];
}
