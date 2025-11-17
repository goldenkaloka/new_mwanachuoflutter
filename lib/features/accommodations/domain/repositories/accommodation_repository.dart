import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/accommodations/domain/entities/accommodation_entity.dart';

abstract class AccommodationRepository {
  Future<Either<Failure, List<AccommodationEntity>>> getAccommodations({
    String? roomType,
    String? universityId,
    String? ownerId,
    bool? isFeatured,
    int? limit,
    int? offset,
  });

  Future<Either<Failure, AccommodationEntity>> getAccommodationById(
    String accommodationId,
  );

  Future<Either<Failure, List<AccommodationEntity>>> getMyAccommodations({
    int? limit,
    int? offset,
  });

  Future<Either<Failure, AccommodationEntity>> createAccommodation({
    required String name,
    required String description,
    required double price,
    required String priceType,
    required String roomType,
    required List<File> images,
    required String location,
    required String contactPhone,
    String? contactEmail,
    required List<String> amenities,
    required int bedrooms,
    required int bathrooms,
    Map<String, dynamic>? metadata,
  });

  Future<Either<Failure, AccommodationEntity>> updateAccommodation({
    required String accommodationId,
    String? name,
    String? description,
    double? price,
    String? priceType,
    String? roomType,
    List<File>? newImages,
    List<String>? existingImages,
    String? location,
    String? contactPhone,
    String? contactEmail,
    List<String>? amenities,
    int? bedrooms,
    int? bathrooms,
    bool? isActive,
    Map<String, dynamic>? metadata,
  });

  Future<Either<Failure, void>> deleteAccommodation(String accommodationId);
  Future<Either<Failure, void>> incrementViewCount(String accommodationId);
}

