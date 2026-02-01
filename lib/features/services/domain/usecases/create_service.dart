import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/services/domain/entities/service_entity.dart';
import 'package:mwanachuo/features/services/domain/repositories/service_repository.dart';

class CreateService implements UseCase<ServiceEntity, CreateServiceParams> {
  final ServiceRepository repository;

  CreateService(this.repository);

  @override
  Future<Either<Failure, ServiceEntity>> call(
    CreateServiceParams params,
  ) async {
    // Validate
    if (params.title.trim().isEmpty) {
      return Left(ValidationFailure('Title cannot be empty'));
    }
    if (params.description.trim().isEmpty) {
      return Left(ValidationFailure('Description cannot be empty'));
    }
    if (params.price <= 0) {
      return Left(ValidationFailure('Price must be greater than 0'));
    }
    if (params.images.isEmpty) {
      return Left(ValidationFailure('At least one image is required'));
    }
    if (params.contactPhone.trim().isEmpty) {
      return Left(ValidationFailure('Contact phone is required'));
    }

    // Check subscription status before creating service
    // Subscription check removed for free market transition
    // final currentUser = SupabaseConfig.client.auth.currentUser;
    // ...

    return await repository.createService(
      title: params.title.trim(),
      description: params.description.trim(),
      price: params.price,
      category: params.category,
      priceType: params.priceType,
      images: params.images,
      location: params.location.trim(),
      contactPhone: params.contactPhone.trim(),
      contactEmail: params.contactEmail?.trim(),
      availability: params.availability,
      metadata: params.metadata,
      isGlobal: params.isGlobal,
    );
  }
}

class CreateServiceParams extends Equatable {
  final String title;
  final String description;
  final double price;
  final String category;
  final String priceType;
  final List<File> images;
  final String location;
  final String contactPhone;
  final String? contactEmail;
  final List<String> availability;
  final Map<String, dynamic>? metadata;
  final bool isGlobal;

  const CreateServiceParams({
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.priceType,
    required this.images,
    required this.location,
    required this.contactPhone,
    this.contactEmail,
    required this.availability,
    this.metadata,
    this.isGlobal = false,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    price,
    category,
    priceType,
    images,
    location,
    contactPhone,
    contactEmail,
    availability,
    metadata,
    isGlobal,
  ];
}
