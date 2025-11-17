import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/services/domain/entities/service_entity.dart';

/// Service repository interface
abstract class ServiceRepository {
  /// Get all services
  Future<Either<Failure, List<ServiceEntity>>> getServices({
    String? category,
    String? universityId,
    String? providerId,
    bool? isFeatured,
    int? limit,
    int? offset,
  });

  /// Get a single service by ID
  Future<Either<Failure, ServiceEntity>> getServiceById(String serviceId);

  /// Get user's services (provider's listings)
  Future<Either<Failure, List<ServiceEntity>>> getMyServices({
    int? limit,
    int? offset,
  });

  /// Create a new service
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
  });

  /// Update a service
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
  });

  /// Delete a service
  Future<Either<Failure, void>> deleteService(String serviceId);

  /// Increment view count
  Future<Either<Failure, void>> incrementViewCount(String serviceId);
}

