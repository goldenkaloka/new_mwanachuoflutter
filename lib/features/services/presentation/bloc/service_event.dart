import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ServiceEvent extends Equatable {
  const ServiceEvent();

  @override
  List<Object?> get props => [];
}

class LoadServicesEvent extends ServiceEvent {
  final String? category;
  final String? universityId;
  final String? providerId;
  final bool? isFeatured;
  final int? limit;
  final int? offset;

  const LoadServicesEvent({
    this.category,
    this.universityId,
    this.providerId,
    this.isFeatured,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [category, universityId, providerId, isFeatured, limit, offset];
}

class LoadServiceByIdEvent extends ServiceEvent {
  final String serviceId;

  const LoadServiceByIdEvent({required this.serviceId});

  @override
  List<Object?> get props => [serviceId];
}

class LoadMyServicesEvent extends ServiceEvent {
  final int? limit;
  final int? offset;

  const LoadMyServicesEvent({this.limit, this.offset});

  @override
  List<Object?> get props => [limit, offset];
}

class CreateServiceEvent extends ServiceEvent {
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

  const CreateServiceEvent({
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
      ];
}

class UpdateServiceEvent extends ServiceEvent {
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

  const UpdateServiceEvent({
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

class DeleteServiceEvent extends ServiceEvent {
  final String serviceId;

  const DeleteServiceEvent({required this.serviceId});

  @override
  List<Object?> get props => [serviceId];
}

class IncrementServiceViewCountEvent extends ServiceEvent {
  final String serviceId;

  const IncrementServiceViewCountEvent({required this.serviceId});

  @override
  List<Object?> get props => [serviceId];
}

