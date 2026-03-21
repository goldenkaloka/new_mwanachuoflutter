import 'package:equatable/equatable.dart';

class Restaurant extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? address;
  final String? phone;
  final String? category;
  final double? rating;
  final double latitude;
  final double longitude;
  final bool isActive;
  final String? deliveryTime;
  final double? deliveryFee;

  const Restaurant({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.address,
    this.phone,
    this.category,
    this.rating,
    required this.latitude,
    required this.longitude,
    this.isActive = true,
    this.deliveryTime,
    this.deliveryFee,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        imageUrl,
        address,
        phone,
        category,
        rating,
        latitude,
        longitude,
        isActive,
        deliveryTime,
        deliveryFee,
      ];
}
