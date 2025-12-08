import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/network/network_info.dart';
import 'package:mwanachuo/features/accommodations/data/datasources/accommodation_remote_data_source.dart';
import 'package:mwanachuo/features/accommodations/domain/entities/accommodation_entity.dart';
import 'package:mwanachuo/features/accommodations/domain/repositories/accommodation_repository.dart';
import 'package:mwanachuo/features/shared/media/domain/usecases/upload_multiple_images.dart';

class AccommodationRepositoryImpl implements AccommodationRepository {
  final AccommodationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final UploadMultipleImages uploadImages;

  AccommodationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.uploadImages,
  });

  @override
  Future<Either<Failure, List<AccommodationEntity>>> getAccommodations({
    String? roomType,
    String? universityId,
    String? ownerId,
    bool? isFeatured,
    int? limit,
    int? offset,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    String? location,
    List<String>? amenities,
    String? priceType,
    String? sortBy,
    bool sortAscending = true,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final accommodations = await remoteDataSource.getAccommodations(
        roomType: roomType,
        universityId: universityId,
        ownerId: ownerId,
        isFeatured: isFeatured,
        limit: limit,
        offset: offset,
        searchQuery: searchQuery,
        minPrice: minPrice,
        maxPrice: maxPrice,
        location: location,
        amenities: amenities,
        priceType: priceType,
        sortBy: sortBy,
        sortAscending: sortAscending,
      );
      return Right(accommodations);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get accommodations: $e'));
    }
  }

  @override
  Future<Either<Failure, AccommodationEntity>> getAccommodationById(
    String accommodationId,
  ) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final accommodation = await remoteDataSource.getAccommodationById(accommodationId);
      return Right(accommodation);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get accommodation: $e'));
    }
  }

  @override
  Future<Either<Failure, List<AccommodationEntity>>> getMyAccommodations({
    int? limit,
    int? offset,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final accommodations = await remoteDataSource.getMyAccommodations(
        limit: limit,
        offset: offset,
      );
      return Right(accommodations);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get my accommodations: $e'));
    }
  }

  @override
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
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final uploadResult = await uploadImages(
        UploadMultipleImagesParams(
          imageFiles: images,
          bucket: DatabaseConstants.accommodationImagesBucket,
          folder: 'accommodations',
        ),
      );

      return await uploadResult.fold(
        (failure) => Left(failure),
        (uploadedMedia) async {
          final imageUrls = uploadedMedia.map((m) => m.url).toList();

          final accommodation = await remoteDataSource.createAccommodation(
            name: name,
            description: description,
            price: price,
            priceType: priceType,
            roomType: roomType,
            imageUrls: imageUrls,
            location: location,
            contactPhone: contactPhone,
            contactEmail: contactEmail,
            amenities: amenities,
            bedrooms: bedrooms,
            bathrooms: bathrooms,
            metadata: metadata,
          );

          return Right(accommodation);
        },
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to create accommodation: $e'));
    }
  }

  @override
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
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      List<String>? finalImageUrls;

      if (newImages != null && newImages.isNotEmpty) {
        final uploadResult = await uploadImages(
          UploadMultipleImagesParams(
            imageFiles: newImages,
            bucket: DatabaseConstants.accommodationImagesBucket,
            folder: 'accommodations',
          ),
        );

        final newImageUrls = uploadResult.fold(
          (failure) => <String>[],
          (uploadedMedia) => uploadedMedia.map((m) => m.url).toList(),
        );

        finalImageUrls = [...(existingImages ?? []), ...newImageUrls];
      } else if (existingImages != null) {
        finalImageUrls = existingImages;
      }

      final accommodation = await remoteDataSource.updateAccommodation(
        accommodationId: accommodationId,
        name: name,
        description: description,
        price: price,
        priceType: priceType,
        roomType: roomType,
        imageUrls: finalImageUrls,
        location: location,
        contactPhone: contactPhone,
        contactEmail: contactEmail,
        amenities: amenities,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        isActive: isActive,
        metadata: metadata,
      );

      return Right(accommodation);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to update accommodation: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccommodation(String accommodationId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.deleteAccommodation(accommodationId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to delete accommodation: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> incrementViewCount(String accommodationId) async {
    if (!await networkInfo.isConnected) {
      return const Right(null);
    }

    try {
      await remoteDataSource.incrementViewCount(accommodationId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to increment view count: $e'));
    }
  }
}

