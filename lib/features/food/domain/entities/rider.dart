import 'package:equatable/equatable.dart';

class Rider extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final String vehicleType;
  final double rating;
  final String? avatarUrl;

  const Rider({
    required this.id,
    required this.name,
    this.phone,
    required this.vehicleType,
    this.rating = 5.0,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [id, name, phone, vehicleType, rating, avatarUrl];
}
