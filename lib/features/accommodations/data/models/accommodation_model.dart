import 'package:mwanachuo/features/accommodations/domain/entities/accommodation_entity.dart';

class AccommodationModel extends AccommodationEntity {
  const AccommodationModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.priceType,
    required super.roomType,
    required super.images,
    required super.ownerId,
    required super.ownerName,
    super.ownerAvatar,
    required super.universityIds,
    required super.location,
    required super.contactPhone,
    super.contactEmail,
    required super.amenities,
    required super.bedrooms,
    required super.bathrooms,
    super.isActive,
    super.isFeatured,
    super.viewCount,
    super.rating,
    super.reviewCount,
    required super.createdAt,
    super.updatedAt,
    super.metadata,
  });

  factory AccommodationModel.fromJson(Map<String, dynamic> json) {
    return AccommodationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      priceType: json['price_type'] as String,
      roomType: json['room_type'] as String,
      images: List<String>.from(json['images'] as List? ?? []),
      ownerId: json['owner_id'] as String,
      ownerName: json['owner_name'] as String? ?? 'Unknown',
      ownerAvatar: json['owner_avatar'] as String?,
      universityIds: List<String>.from(json['university_ids'] as List? ?? []),
      location: json['location'] as String,
      contactPhone: json['contact_phone'] as String,
      contactEmail: json['contact_email'] as String?,
      amenities: List<String>.from(json['amenities'] as List? ?? []),
      bedrooms: json['bedrooms'] as int,
      bathrooms: json['bathrooms'] as int,
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      viewCount: json['view_count'] as int? ?? 0,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewCount: json['review_count'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'price_type': priceType,
      'room_type': roomType,
      'images': images,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'owner_avatar': ownerAvatar,
      'university_ids': universityIds,
      'location': location,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'amenities': amenities,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'is_active': isActive,
      'is_featured': isFeatured,
      'view_count': viewCount,
      'rating': rating,
      'review_count': reviewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
}

