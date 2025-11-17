import 'package:equatable/equatable.dart';

class AccommodationEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String priceType; // per_month, per_semester, per_year
  final String roomType; // single, shared, studio, apartment
  final List<String> images;
  final String ownerId;
  final String ownerName;
  final String? ownerAvatar;
  final List<String> universityIds;
  final String location;
  final String contactPhone;
  final String? contactEmail;
  final List<String> amenities;
  final int bedrooms;
  final int bathrooms;
  final bool isActive;
  final bool isFeatured;
  final int viewCount;
  final double? rating;
  final int? reviewCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  const AccommodationEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.priceType,
    required this.roomType,
    required this.images,
    required this.ownerId,
    required this.ownerName,
    this.ownerAvatar,
    required this.universityIds,
    required this.location,
    required this.contactPhone,
    this.contactEmail,
    required this.amenities,
    required this.bedrooms,
    required this.bathrooms,
    this.isActive = true,
    this.isFeatured = false,
    this.viewCount = 0,
    this.rating,
    this.reviewCount,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        priceType,
        roomType,
        images,
        ownerId,
        ownerName,
        ownerAvatar,
        universityIds,
        location,
        contactPhone,
        contactEmail,
        amenities,
        bedrooms,
        bathrooms,
        isActive,
        isFeatured,
        viewCount,
        rating,
        reviewCount,
        createdAt,
        updatedAt,
        metadata,
      ];
}

