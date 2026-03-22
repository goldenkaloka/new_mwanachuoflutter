import 'package:equatable/equatable.dart';

class Rider extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final String vehicleType;
  final double rating;
  final String? avatarUrl;
  final bool isOnline;
  final double? currentLat;
  final double? currentLng;

  const Rider({
    required this.id,
    required this.name,
    this.phone,
    required this.vehicleType,
    this.rating = 5.0,
    this.avatarUrl,
    this.isOnline = false,
    this.currentLat,
    this.currentLng,
  });

  Rider copyWith({
    String? id,
    String? name,
    String? phone,
    String? vehicleType,
    double? rating,
    String? avatarUrl,
    bool? isOnline,
    double? currentLat,
    double? currentLng,
  }) {
    return Rider(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      vehicleType: vehicleType ?? this.vehicleType,
      rating: rating ?? this.rating,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, vehicleType, rating, avatarUrl, isOnline, currentLat, currentLng];
}
