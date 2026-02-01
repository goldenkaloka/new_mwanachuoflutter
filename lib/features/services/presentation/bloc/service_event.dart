import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/models/filter_model.dart';

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
  final ServiceFilter? filter;

  const LoadServicesEvent({
    this.category,
    this.universityId,
    this.providerId,
    this.isFeatured,
    this.limit,
    this.offset,
    this.filter,
  });

  @override
  List<Object?> get props => [
    category,
    universityId,
    providerId,
    isFeatured,
    limit,
    offset,
    filter,
  ];
}

/// Apply filter event
class ApplyServiceFilterEvent extends ServiceEvent {
  final ServiceFilter filter;

  const ApplyServiceFilterEvent({required this.filter});

  @override
  List<Object?> get props => [filter];
}

/// Clear filter event
class ClearServiceFilterEvent extends ServiceEvent {
  const ClearServiceFilterEvent();
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
  final bool isGlobal;

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

class LoadMoreServicesEvent extends ServiceEvent {
  final String? category;
  final String? universityId;
  final int offset;
  final ServiceFilter? filter;

  const LoadMoreServicesEvent({
    this.category,
    this.universityId,
    required this.offset,
    this.filter,
  });

  @override
  List<Object?> get props => [category, universityId, offset, filter];
}
