import 'package:equatable/equatable.dart';

class FoodAdditive extends Equatable {
  final String id;
  final String foodItemId;
  final String name;
  final double price;
  final bool isAvailable;

  const FoodAdditive({
    required this.id,
    required this.foodItemId,
    required this.name,
    required this.price,
    this.isAvailable = true,
  });

  @override
  List<Object?> get props => [id, foodItemId, name, price, isAvailable];
}
