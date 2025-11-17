import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/network/network_info.dart';
import 'package:mwanachuo/features/services/data/datasources/service_local_data_source.dart';
import 'package:mwanachuo/features/services/data/datasources/service_remote_data_source.dart';
import 'package:mwanachuo/features/services/domain/entities/service_entity.dart';
import 'package:mwanachuo/features/services/domain/repositories/service_repository.dart';
import 'package:mwanachuo/features/shared/media/domain/usecases/upload_multiple_images.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteDataSource remoteDataSource;
  final ServiceLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final UploadMultipleImages uploadImages;

  ServiceRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.uploadImages,
  });

  @override
  Future<Either<Failure, List<ServiceEntity>>> getServices({
    String? category,
    String? universityId,
    String? providerId,
    bool? isFeatured,
    int? limit,
    int? offset,
  }) async {
    if (!await networkInfo.isConnected) {
      try {
        final cached = await localDataSource.getCachedServices();
        return Right(cached);
      } on CacheException {
        return Left(NetworkFailure('No internet connection and no cached data'));
      }
    }

    try {
      final services = await remoteDataSource.getServices(
        category: category,
        universityId: universityId,
        providerId: providerId,
        isFeatured: isFeatured,
        limit: limit,
        offset: offset,
      );
      await localDataSource.cacheServices(services);
      return Right(services);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get services: $e'));
    }
  }

  @override
  Future<Either<Failure, ServiceEntity>> getServiceById(String serviceId) async {
    if (!await networkInfo.isConnected) {
      try {
        final cached = await localDataSource.getCachedService(serviceId);
        return Right(cached);
      } on CacheException {
        return Left(NetworkFailure('No internet connection and no cached data'));
      }
    }

    try {
      final service = await remoteDataSource.getServiceById(serviceId);
      await localDataSource.cacheService(service);
      return Right(service);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get service: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ServiceEntity>>> getMyServices({
    int? limit,
    int? offset,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final services = await remoteDataSource.getMyServices(
        limit: limit,
        offset: offset,
      );
      return Right(services);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get my services: $e'));
    }
  }

  @override
  Future<Either<Failure, ServiceEntity>> createService({
    required String title,
    required String description,
    required double price,
    required String category,
    required String priceType,
    required List<File> images,
    required String location,
    required String contactPhone,
    String? contactEmail,
    required List<String> availability,
    Map<String, dynamic>? metadata,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final uploadResult = await uploadImages(
        UploadMultipleImagesParams(
          imageFiles: images,
          bucket: DatabaseConstants.serviceImagesBucket,
          folder: 'services',
        ),
      );

      return await uploadResult.fold(
        (failure) => Left(failure),
        (uploadedMedia) async {
          final imageUrls = uploadedMedia.map((m) => m.url).toList();

          final service = await remoteDataSource.createService(
            title: title,
            description: description,
            price: price,
            category: category,
            priceType: priceType,
            imageUrls: imageUrls,
            location: location,
            contactPhone: contactPhone,
            contactEmail: contactEmail,
            availability: availability,
            metadata: metadata,
          );

          // Add service to cache (incremental update)
          try {
            await localDataSource.addServiceToCache(service);
          } catch (e) {
            // Non-critical error, continue
          }
          
          return Right(service);
        },
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to create service: $e'));
    }
  }

  @override
  Future<Either<Failure, ServiceEntity>> updateService({
    required String serviceId,
    String? title,
    String? description,
    double? price,
    String? category,
    String? priceType,
    List<File>? newImages,
    List<String>? existingImages,
    String? location,
    String? contactPhone,
    String? contactEmail,
    List<String>? availability,
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
            bucket: DatabaseConstants.serviceImagesBucket,
            folder: 'services',
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

      final service = await remoteDataSource.updateService(
        serviceId: serviceId,
        title: title,
        description: description,
        price: price,
        category: category,
        priceType: priceType,
        imageUrls: finalImageUrls,
        location: location,
        contactPhone: contactPhone,
        contactEmail: contactEmail,
        availability: availability,
        isActive: isActive,
        metadata: metadata,
      );

      // Update service in cache (incremental update)
      try {
        await localDataSource.updateServiceInCache(service);
      } catch (e) {
        // Non-critical error, continue
      }
      
      return Right(service);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to update service: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteService(String serviceId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.deleteService(serviceId);
      await localDataSource.clearCache();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to delete service: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> incrementViewCount(String serviceId) async {
    if (!await networkInfo.isConnected) {
      return const Right(null);
    }

    try {
      await remoteDataSource.incrementViewCount(serviceId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to increment view count: $e'));
    }
  }
}

