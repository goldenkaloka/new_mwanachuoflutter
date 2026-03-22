import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/food/domain/entities/food_additive.dart';

class FoodItem extends Equatable {
  final String id;
  final String restaurantId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final String? category;
  final bool isAvailable;
  final List<FoodAdditive>? additives;

  const FoodItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.category,
    this.isAvailable = true,
    this.additives,
  });

  @override
  List<Object?> get props => [id, restaurantId, name, description, price, imageUrl, category, isAvailable, additives];

  FoodItem copyWith({
    String? id,
    String? restaurantId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    bool? isAvailable,
    List<FoodAdditive>? additives,
  }) {
    return FoodItem(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      additives: additives ?? this.additives,
    );
  }
}
