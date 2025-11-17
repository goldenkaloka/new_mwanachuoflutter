import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/services/domain/entities/service_entity.dart';

abstract class ServiceState extends Equatable {
  const ServiceState();

  @override
  List<Object?> get props => [];
}

class ServiceInitial extends ServiceState {}

class ServicesLoading extends ServiceState {}

class ServicesLoaded extends ServiceState {
  final List<ServiceEntity> services;
  final bool hasMore;
  final bool isLoadingMore;

  const ServicesLoaded({
    required this.services,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  ServicesLoaded copyWith({
    List<ServiceEntity>? services,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return ServicesLoaded(
      services: services ?? this.services,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [services, hasMore, isLoadingMore];
}

class ServiceLoading extends ServiceState {}

class ServiceLoaded extends ServiceState {
  final ServiceEntity service;

  const ServiceLoaded({required this.service});

  @override
  List<Object?> get props => [service];
}

class ServiceCreating extends ServiceState {}

class ServiceCreated extends ServiceState {
  final ServiceEntity service;

  const ServiceCreated({required this.service});

  @override
  List<Object?> get props => [service];
}

class ServiceUpdating extends ServiceState {}

class ServiceUpdated extends ServiceState {
  final ServiceEntity service;

  const ServiceUpdated({required this.service});

  @override
  List<Object?> get props => [service];
}

class ServiceDeleting extends ServiceState {}

class ServiceDeleted extends ServiceState {}

class ServiceError extends ServiceState {
  final String message;

  const ServiceError({required this.message});

  @override
  List<Object?> get props => [message];
}

