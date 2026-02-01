import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/accommodations/domain/entities/accommodation_entity.dart';
import 'package:mwanachuo/features/accommodations/domain/repositories/accommodation_repository.dart';

class CreateAccommodation
    implements UseCase<AccommodationEntity, CreateAccommodationParams> {
  final AccommodationRepository repository;

  CreateAccommodation(this.repository);

  @override
  Future<Either<Failure, AccommodationEntity>> call(
    CreateAccommodationParams params,
  ) async {
    if (params.name.trim().isEmpty) {
      return Left(ValidationFailure('Name cannot be empty'));
    }
    if (params.price <= 0) {
      return Left(ValidationFailure('Price must be greater than 0'));
    }
    if (params.images.isEmpty) {
      return Left(ValidationFailure('At least one image is required'));
    }

    // Check subscription status before creating accommodation
    // Subscription check removed for free market transition
    // final currentUser = SupabaseConfig.client.auth.currentUser;
    // ...

    return await repository.createAccommodation(
      name: params.name.trim(),
      description: params.description.trim(),
      price: params.price,
      priceType: params.priceType,
      roomType: params.roomType,
      images: params.images,
      location: params.location.trim(),
      contactPhone: params.contactPhone.trim(),
      contactEmail: params.contactEmail?.trim(),
      amenities: params.amenities,
      bedrooms: params.bedrooms,
      bathrooms: params.bathrooms,
      metadata: params.metadata,
      isGlobal: params.isGlobal,
    );
  }
}

class CreateAccommodationParams extends Equatable {
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
  final bool isGlobal;

  const CreateAccommodationParams({
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
    this.isGlobal = false,
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
    isGlobal,
  ];
}
