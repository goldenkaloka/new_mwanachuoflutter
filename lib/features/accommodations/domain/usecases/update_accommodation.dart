import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/accommodations/domain/entities/accommodation_entity.dart';
import 'package:mwanachuo/features/accommodations/domain/repositories/accommodation_repository.dart';

class UpdateAccommodation
    implements UseCase<AccommodationEntity, UpdateAccommodationParams> {
  final AccommodationRepository repository;

  UpdateAccommodation(this.repository);

  @override
  Future<Either<Failure, AccommodationEntity>> call(
      UpdateAccommodationParams params) async {
    return await repository.updateAccommodation(
      accommodationId: params.accommodationId,
      name: params.name,
      description: params.description,
      price: params.price,
      priceType: params.priceType,
      roomType: params.roomType,
      newImages: params.newImages,
      existingImages: params.existingImages,
      location: params.location,
      contactPhone: params.contactPhone,
      contactEmail: params.contactEmail,
      amenities: params.amenities,
      bedrooms: params.bedrooms,
      bathrooms: params.bathrooms,
      isActive: params.isActive,
      metadata: params.metadata,
    );
  }
}

class UpdateAccommodationParams extends Equatable {
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

  const UpdateAccommodationParams({
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

