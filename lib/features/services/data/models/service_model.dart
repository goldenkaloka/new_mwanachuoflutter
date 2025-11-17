import 'package:mwanachuo/features/services/domain/entities/service_entity.dart';

class ServiceModel extends ServiceEntity {
  const ServiceModel({
    required super.id,
    required super.title,
    required super.description,
    required super.price,
    required super.category,
    required super.priceType,
    required super.images,
    required super.providerId,
    required super.providerName,
    super.providerAvatar,
    required super.universityIds,
    required super.location,
    required super.contactPhone,
    super.contactEmail,
    required super.availability,
    super.isActive,
    super.isFeatured,
    super.viewCount,
    super.rating,
    super.reviewCount,
    required super.createdAt,
    super.updatedAt,
    super.metadata,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      priceType: json['price_type'] as String,
      images: List<String>.from(json['images'] as List? ?? []),
      providerId: json['provider_id'] as String,
      providerName: json['provider_name'] as String? ?? 'Unknown',
      providerAvatar: json['provider_avatar'] as String?,
      universityIds: List<String>.from(json['university_ids'] as List? ?? []),
      location: json['location'] as String,
      contactPhone: json['contact_phone'] as String,
      contactEmail: json['contact_email'] as String?,
      availability: List<String>.from(json['availability'] as List? ?? []),
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
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'price_type': priceType,
      'images': images,
      'provider_id': providerId,
      'provider_name': providerName,
      'provider_avatar': providerAvatar,
      'university_ids': universityIds,
      'location': location,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'availability': availability,
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

