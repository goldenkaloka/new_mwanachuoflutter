import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/services/domain/usecases/create_service.dart';
import 'package:mwanachuo/features/services/domain/usecases/delete_service.dart';
import 'package:mwanachuo/features/services/domain/usecases/get_my_services.dart';
import 'package:mwanachuo/features/services/domain/usecases/get_service_by_id.dart';
import 'package:mwanachuo/features/services/domain/usecases/get_services.dart';
import 'package:mwanachuo/features/services/domain/usecases/update_service.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_event.dart';
import 'package:mwanachuo/features/services/presentation/bloc/service_state.dart';

class ServiceBloc extends Bloc<ServiceEvent, ServiceState> {
  final GetServices getServices;
  final GetServiceById getServiceById;
  final GetMyServices getMyServices;
  final CreateService createService;
  final UpdateService updateService;
  final DeleteService deleteService;

  ServiceBloc({
    required this.getServices,
    required this.getServiceById,
    required this.getMyServices,
    required this.createService,
    required this.updateService,
    required this.deleteService,
  }) : super(ServiceInitial()) {
    on<LoadServicesEvent>(_onLoadServices);
    on<LoadServiceByIdEvent>(_onLoadServiceById);
    on<LoadMyServicesEvent>(_onLoadMyServices);
    on<CreateServiceEvent>(_onCreateService);
    on<UpdateServiceEvent>(_onUpdateService);
    on<DeleteServiceEvent>(_onDeleteService);
  }

  Future<void> _onLoadServices(
    LoadServicesEvent event,
    Emitter<ServiceState> emit,
  ) async {
    // Prevent reloading if already loading
    if (state is ServicesLoading) {
      debugPrint('⏭️  Services already loading, skipping...');
      return;
    }
    
    debugPrint('🔧 Loading services...');
    emit(ServicesLoading());

    final result = await getServices(
      GetServicesParams(
        category: event.category,
        universityId: event.universityId,
        providerId: event.providerId,
        isFeatured: event.isFeatured,
        limit: event.limit,
        offset: event.offset,
      ),
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        debugPrint('❌ Services load failed: ${failure.message}');
        emit(ServiceError(message: failure.message));
      },
      (services) {
        debugPrint('✅ Services loaded: ${services.length} items');
        emit(ServicesLoaded(
          services: services,
          hasMore: services.length == (event.limit ?? 20),
        ));
      },
    );
  }

  Future<void> _onLoadServiceById(
    LoadServiceByIdEvent event,
    Emitter<ServiceState> emit,
  ) async {
    emit(ServiceLoading());

    final result = await getServiceById(
      GetServiceByIdParams(serviceId: event.serviceId),
    );

    result.fold(
      (failure) => emit(ServiceError(message: failure.message)),
      (service) => emit(ServiceLoaded(service: service)),
    );
  }

  Future<void> _onLoadMyServices(
    LoadMyServicesEvent event,
    Emitter<ServiceState> emit,
  ) async {
    emit(ServicesLoading());

    final result = await getMyServices(
      GetMyServicesParams(limit: event.limit, offset: event.offset),
    );

    result.fold(
      (failure) => emit(ServiceError(message: failure.message)),
      (services) => emit(ServicesLoaded(services: services)),
    );
  }

  Future<void> _onCreateService(
    CreateServiceEvent event,
    Emitter<ServiceState> emit,
  ) async {
    emit(ServiceCreating());

    final result = await createService(
      CreateServiceParams(
        title: event.title,
        description: event.description,
        price: event.price,
        category: event.category,
        priceType: event.priceType,
        images: event.images,
        location: event.location,
        contactPhone: event.contactPhone,
        contactEmail: event.contactEmail,
        availability: event.availability,
        metadata: event.metadata,
      ),
    );

    result.fold(
      (failure) => emit(ServiceError(message: failure.message)),
      (service) => emit(ServiceCreated(service: service)),
    );
  }

  Future<void> _onUpdateService(
    UpdateServiceEvent event,
    Emitter<ServiceState> emit,
  ) async {
    emit(ServiceUpdating());

    final result = await updateService(
      UpdateServiceParams(
        serviceId: event.serviceId,
        title: event.title,
        description: event.description,
        price: event.price,
        category: event.category,
        priceType: event.priceType,
        newImages: event.newImages,
        existingImages: event.existingImages,
        location: event.location,
        contactPhone: event.contactPhone,
        contactEmail: event.contactEmail,
        availability: event.availability,
        isActive: event.isActive,
        metadata: event.metadata,
      ),
    );

    result.fold(
      (failure) => emit(ServiceError(message: failure.message)),
      (service) => emit(ServiceUpdated(service: service)),
    );
  }

  Future<void> _onDeleteService(
    DeleteServiceEvent event,
    Emitter<ServiceState> emit,
  ) async {
    emit(ServiceDeleting());

    final result = await deleteService(
      DeleteServiceParams(serviceId: event.serviceId),
    );

    result.fold(
      (failure) => emit(ServiceError(message: failure.message)),
      (_) => emit(ServiceDeleted()),
    );
  }
}

