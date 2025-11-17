import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/services/logger_service.dart';
import 'package:mwanachuo/features/accommodations/domain/usecases/create_accommodation.dart';
import 'package:mwanachuo/features/accommodations/domain/usecases/delete_accommodation.dart';
import 'package:mwanachuo/features/accommodations/domain/usecases/get_accommodations.dart';
import 'package:mwanachuo/features/accommodations/domain/usecases/get_my_accommodations.dart';
import 'package:mwanachuo/features/accommodations/domain/usecases/increment_view_count.dart';
import 'package:mwanachuo/features/accommodations/domain/usecases/update_accommodation.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_event.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_state.dart';

class AccommodationBloc extends Bloc<AccommodationEvent, AccommodationState> {
  final GetAccommodations getAccommodations;
  final GetMyAccommodations getMyAccommodations;
  final CreateAccommodation createAccommodation;
  final UpdateAccommodation updateAccommodation;
  final DeleteAccommodation deleteAccommodation;
  final IncrementViewCount incrementViewCount;

  AccommodationBloc({
    required this.getAccommodations,
    required this.getMyAccommodations,
    required this.createAccommodation,
    required this.updateAccommodation,
    required this.deleteAccommodation,
    required this.incrementViewCount,
  }) : super(AccommodationInitial()) {
    on<LoadAccommodationsEvent>(_onLoadAccommodations);
    on<LoadMyAccommodationsEvent>(_onLoadMyAccommodations);
    on<CreateAccommodationEvent>(_onCreateAccommodation);
    on<UpdateAccommodationEvent>(_onUpdateAccommodation);
    on<DeleteAccommodationEvent>(_onDeleteAccommodation);
    on<IncrementViewCountEvent>(_onIncrementViewCount);
    on<LoadMoreAccommodationsEvent>(_onLoadMoreAccommodations);
  }

  Future<void> _onLoadAccommodations(
    LoadAccommodationsEvent event,
    Emitter<AccommodationState> emit,
  ) async {
    // Prevent reloading if already loading
    if (state is AccommodationsLoading) {
      LoggerService.debug('Accommodations already loading, skipping...');
      return;
    }
    
    LoggerService.info('Loading accommodations...');
    emit(AccommodationsLoading());

    final result = await getAccommodations(
      GetAccommodationsParams(
        roomType: event.roomType,
        universityId: event.universityId,
        ownerId: event.ownerId,
        isFeatured: event.isFeatured,
        limit: event.limit,
        offset: event.offset,
      ),
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        LoggerService.error('Accommodations load failed', failure.message);
        emit(AccommodationError(message: failure.message));
      },
      (accommodations) {
        LoggerService.info('Accommodations loaded: ${accommodations.length} items');
        emit(AccommodationsLoaded(
          accommodations: accommodations,
          hasMore: accommodations.length == (event.limit ?? 20),
        ));
      },
    );
  }

  Future<void> _onLoadMyAccommodations(
    LoadMyAccommodationsEvent event,
    Emitter<AccommodationState> emit,
  ) async {
    emit(AccommodationsLoading());

    final result = await getMyAccommodations(
      GetMyAccommodationsParams(
        limit: event.limit,
        offset: event.offset,
      ),
    );

    result.fold(
      (failure) => emit(AccommodationError(message: failure.message)),
      (accommodations) => emit(AccommodationsLoaded(
        accommodations: accommodations,
        hasMore: accommodations.length == (event.limit ?? 20),
      )),
    );
  }

  Future<void> _onCreateAccommodation(
    CreateAccommodationEvent event,
    Emitter<AccommodationState> emit,
  ) async {
    emit(AccommodationCreating());

    final result = await createAccommodation(
      CreateAccommodationParams(
        name: event.name,
        description: event.description,
        price: event.price,
        priceType: event.priceType,
        roomType: event.roomType,
        images: event.images,
        location: event.location,
        contactPhone: event.contactPhone,
        contactEmail: event.contactEmail,
        amenities: event.amenities,
        bedrooms: event.bedrooms,
        bathrooms: event.bathrooms,
        metadata: event.metadata,
      ),
    );

    result.fold(
      (failure) => emit(AccommodationError(message: failure.message)),
      (accommodation) => emit(AccommodationCreated(accommodation: accommodation)),
    );
  }

  Future<void> _onUpdateAccommodation(
    UpdateAccommodationEvent event,
    Emitter<AccommodationState> emit,
  ) async {
    emit(AccommodationUpdating());

    final result = await updateAccommodation(
      UpdateAccommodationParams(
        accommodationId: event.accommodationId,
        name: event.name,
        description: event.description,
        price: event.price,
        priceType: event.priceType,
        roomType: event.roomType,
        newImages: event.newImages,
        existingImages: event.existingImages,
        location: event.location,
        contactPhone: event.contactPhone,
        contactEmail: event.contactEmail,
        amenities: event.amenities,
        bedrooms: event.bedrooms,
        bathrooms: event.bathrooms,
        isActive: event.isActive,
        metadata: event.metadata,
      ),
    );

    result.fold(
      (failure) => emit(AccommodationError(message: failure.message)),
      (accommodation) => emit(AccommodationUpdated(accommodation: accommodation)),
    );
  }

  Future<void> _onDeleteAccommodation(
    DeleteAccommodationEvent event,
    Emitter<AccommodationState> emit,
  ) async {
    emit(AccommodationDeleting());

    final result = await deleteAccommodation(
      DeleteAccommodationParams(accommodationId: event.accommodationId),
    );

    result.fold(
      (failure) => emit(AccommodationError(message: failure.message)),
      (_) => emit(AccommodationDeleted()),
    );
  }

  Future<void> _onIncrementViewCount(
    IncrementViewCountEvent event,
    Emitter<AccommodationState> emit,
  ) async {
    // Silently increment view count, don't change state
    await incrementViewCount(
      IncrementViewCountParams(accommodationId: event.accommodationId),
    );
  }

  Future<void> _onLoadMoreAccommodations(
    LoadMoreAccommodationsEvent event,
    Emitter<AccommodationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AccommodationsLoaded || currentState.isLoadingMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await getAccommodations(
      GetAccommodationsParams(
        roomType: event.roomType,
        universityId: event.universityId,
        limit: 20,
        offset: event.offset,
      ),
    );

    result.fold(
      (failure) => emit(currentState.copyWith(isLoadingMore: false)),
      (newAccommodations) {
        final allAccommodations = [
          ...currentState.accommodations,
          ...newAccommodations,
        ];
        emit(AccommodationsLoaded(
          accommodations: allAccommodations,
          hasMore: newAccommodations.length == 20,
          isLoadingMore: false,
        ));
      },
    );
  }
}

