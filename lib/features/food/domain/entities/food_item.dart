import 'package:equatable/equatable.dart';

class FoodItem extends Equatable {
  final String id;
  final String restaurantId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final String? category;
  final bool isAvailable;

  const FoodItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.category,
    this.isAvailable = true,
  });

  @override
  List<Object?> get props => [id, restaurantId, name, description, price, imageUrl, category, isAvailable];
}
