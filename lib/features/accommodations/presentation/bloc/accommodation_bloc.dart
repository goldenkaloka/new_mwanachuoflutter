import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/accommodations/domain/usecases/create_accommodation.dart';
import 'package:mwanachuo/features/accommodations/domain/usecases/get_accommodations.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_event.dart';
import 'package:mwanachuo/features/accommodations/presentation/bloc/accommodation_state.dart';

class AccommodationBloc extends Bloc<AccommodationEvent, AccommodationState> {
  final GetAccommodations getAccommodations;
  final CreateAccommodation createAccommodation;

  AccommodationBloc({
    required this.getAccommodations,
    required this.createAccommodation,
  }) : super(AccommodationInitial()) {
    on<LoadAccommodationsEvent>(_onLoadAccommodations);
    on<CreateAccommodationEvent>(_onCreateAccommodation);
  }

  Future<void> _onLoadAccommodations(
    LoadAccommodationsEvent event,
    Emitter<AccommodationState> emit,
  ) async {
    // Prevent reloading if already loading
    if (state is AccommodationsLoading) {
      debugPrint('⏭️  Accommodations already loading, skipping...');
      return;
    }
    
    debugPrint('🏠 Loading accommodations...');
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
        debugPrint('❌ Accommodations load failed: ${failure.message}');
        emit(AccommodationError(message: failure.message));
      },
      (accommodations) {
        debugPrint('✅ Accommodations loaded: ${accommodations.length} items');
        emit(AccommodationsLoaded(
          accommodations: accommodations,
          hasMore: accommodations.length == (event.limit ?? 20),
        ));
      },
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
}

