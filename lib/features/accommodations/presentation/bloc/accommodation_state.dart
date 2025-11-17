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
  final bool isLoadingMore;

  const AccommodationsLoaded({
    required this.accommodations,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  AccommodationsLoaded copyWith({
    List<AccommodationEntity>? accommodations,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return AccommodationsLoaded(
      accommodations: accommodations ?? this.accommodations,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [accommodations, hasMore, isLoadingMore];
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

class AccommodationUpdating extends AccommodationState {}

class AccommodationUpdated extends AccommodationState {
  final AccommodationEntity accommodation;

  const AccommodationUpdated({required this.accommodation});

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

