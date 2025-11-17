import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/accommodations/domain/entities/accommodation_entity.dart';

abstract class AccommodationState extends Equatable {
  const AccommodationState();

  @override
  List<Object?> get props => [];
}

class AccommodationInitial extends AccommodationState {}

class AccommodationsLoading extends AccommodationState {}

class AccommodationsLoaded extends AccommodationState {
  final List<AccommodationEntity> accommodations;
  final bool hasMore;

  const AccommodationsLoaded({
    required this.accommodations,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [accommodations, hasMore];
}

class AccommodationLoading extends AccommodationState {}

class AccommodationLoaded extends AccommodationState {
  final AccommodationEntity accommodation;

  const AccommodationLoaded({required this.accommodation});

  @override
  List<Object?> get props => [accommodation];
}

class AccommodationCreating extends AccommodationState {}

class AccommodationCreated extends AccommodationState {
  final AccommodationEntity accommodation;

  const AccommodationCreated({required this.accommodation});

  @override
  List<Object?> get props => [accommodation];
}

class AccommodationDeleting extends AccommodationState {}

class AccommodationDeleted extends AccommodationState {}

class AccommodationError extends AccommodationState {
  final String message;

  const AccommodationError({required this.message});

  @override
  List<Object?> get props => [message];
}

