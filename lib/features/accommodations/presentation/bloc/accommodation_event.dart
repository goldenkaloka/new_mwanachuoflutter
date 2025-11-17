import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class AccommodationEvent extends Equatable {
  const AccommodationEvent();

  @override
  List<Object?> get props => [];
}

class LoadAccommodationsEvent extends AccommodationEvent {
  final String? roomType;
  final String? universityId;
  final String? ownerId;
  final bool? isFeatured;
  final int? limit;
  final int? offset;

  const LoadAccommodationsEvent({
    this.roomType,
    this.universityId,
    this.ownerId,
    this.isFeatured,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [roomType, universityId, ownerId, isFeatured, limit, offset];
}

class LoadAccommodationByIdEvent extends AccommodationEvent {
  final String accommodationId;

  const LoadAccommodationByIdEvent({required this.accommodationId});

  @override
  List<Object?> get props => [accommodationId];
}

class CreateAccommodationEvent extends AccommodationEvent {
  final String name;
  final String description;
  final double price;
  final String priceType;
  final String roomType;
  final List<File> images;
  final String location;
  final String contactPhone;
  final String? contactEmail;
  final List<String> amenities;
  final int bedrooms;
  final int bathrooms;
  final Map<String, dynamic>? metadata;

  const CreateAccommodationEvent({
    required this.name,
    required this.description,
    required this.price,
    required this.priceType,
    required this.roomType,
    required this.images,
    required this.location,
    required this.contactPhone,
    this.contactEmail,
    required this.amenities,
    required this.bedrooms,
    required this.bathrooms,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        name,
        description,
        price,
        priceType,
        roomType,
        images,
        location,
        contactPhone,
        contactEmail,
        amenities,
        bedrooms,
        bathrooms,
        metadata,
      ];
}

class LoadMyAccommodationsEvent extends AccommodationEvent {
  final int? limit;
  final int? offset;

  const LoadMyAccommodationsEvent({
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [limit, offset];
}

class UpdateAccommodationEvent extends AccommodationEvent {
  final String accommodationId;
  final String? name;
  final String? description;
  final double? price;
  final String? priceType;
  final String? roomType;
  final List<File>? newImages;
  final List<String>? existingImages;
  final String? location;
  final String? contactPhone;
  final String? contactEmail;
  final List<String>? amenities;
  final int? bedrooms;
  final int? bathrooms;
  final bool? isActive;
  final Map<String, dynamic>? metadata;

  const UpdateAccommodationEvent({
    required this.accommodationId,
    this.name,
    this.description,
    this.price,
    this.priceType,
    this.roomType,
    this.newImages,
    this.existingImages,
    this.location,
    this.contactPhone,
    this.contactEmail,
    this.amenities,
    this.bedrooms,
    this.bathrooms,
    this.isActive,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        accommodationId,
        name,
        description,
        price,
        priceType,
        roomType,
        newImages,
        existingImages,
        location,
        contactPhone,
        contactEmail,
        amenities,
        bedrooms,
        bathrooms,
        isActive,
        metadata,
      ];
}

class DeleteAccommodationEvent extends AccommodationEvent {
  final String accommodationId;

  const DeleteAccommodationEvent({required this.accommodationId});

  @override
  List<Object?> get props => [accommodationId];
}

class IncrementViewCountEvent extends AccommodationEvent {
  final String accommodationId;

  const IncrementViewCountEvent({required this.accommodationId});

  @override
  List<Object?> get props => [accommodationId];
}

class LoadMoreAccommodationsEvent extends AccommodationEvent {
  final String? roomType;
  final String? universityId;
  final int offset;

  const LoadMoreAccommodationsEvent({
    this.roomType,
    this.universityId,
    required this.offset,
  });

  @override
  List<Object?> get props => [roomType, universityId, offset];
}

