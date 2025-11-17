import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/services/domain/entities/service_entity.dart';
import 'package:mwanachuo/features/services/domain/repositories/service_repository.dart';

class UpdateService implements UseCase<ServiceEntity, UpdateServiceParams> {
  final ServiceRepository repository;

  UpdateService(this.repository);

  @override
  Future<Either<Failure, ServiceEntity>> call(UpdateServiceParams params) async {
    return await repository.updateService(
      serviceId: params.serviceId,
      title: params.title,
      description: params.description,
      price: params.price,
      category: params.category,
      priceType: params.priceType,
      newImages: params.newImages,
      existingImages: params.existingImages,
      location: params.location,
      contactPhone: params.contactPhone,
      contactEmail: params.contactEmail,
      availability: params.availability,
      isActive: params.isActive,
      metadata: params.metadata,
    );
  }
}

class UpdateServiceParams extends Equatable {
  final String serviceId;
  final String? title;
  final String? description;
  final double? price;
  final String? category;
  final String? priceType;
  final List<File>? newImages;
  final List<String>? existingImages;
  final String? location;
  final String? contactPhone;
  final String? contactEmail;
  final List<String>? availability;
  final bool? isActive;
  final Map<String, dynamic>? metadata;

  const UpdateServiceParams({
    required this.serviceId,
    this.title,
    this.description,
    this.price,
    this.category,
    this.priceType,
    this.newImages,
    this.existingImages,
    this.location,
    this.contactPhone,
    this.contactEmail,
    this.availability,
    this.isActive,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        serviceId,
        title,
        description,
        price,
        category,
        priceType,
        newImages,
        existingImages,
        location,
        contactPhone,
        contactEmail,
        availability,
        isActive,
        metadata,
      ];
}

