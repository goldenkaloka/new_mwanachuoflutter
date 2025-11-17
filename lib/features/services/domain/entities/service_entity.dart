import 'package:equatable/equatable.dart';

/// Service entity representing a marketplace service
class ServiceEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String priceType; // hourly, fixed, per_session
  final List<String> images;
  final String providerId;
  final String providerName;
  final String? providerAvatar;
  final List<String> universityIds;
  final String location;
  final String contactPhone;
  final String? contactEmail;
  final List<String> availability; // days or time slots
  final bool isActive;
  final bool isFeatured;
  final int viewCount;
  final double? rating;
  final int? reviewCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  const ServiceEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.priceType,
    required this.images,
    required this.providerId,
    required this.providerName,
    this.providerAvatar,
    required this.universityIds,
    required this.location,
    required this.contactPhone,
    this.contactEmail,
    required this.availability,
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
        title,
        description,
        price,
        category,
        priceType,
        images,
        providerId,
        providerName,
        providerAvatar,
        universityIds,
        location,
        contactPhone,
        contactEmail,
        availability,
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

