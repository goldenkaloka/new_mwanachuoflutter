import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_criteria_entity.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_type.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/usecases/get_accommodation_recommendations.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/usecases/get_product_recommendations.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/usecases/get_service_recommendations.dart';
import 'package:mwanachuo/features/shared/recommendations/presentation/cubit/recommendation_state.dart';

/// Cubit for managing recommendation state
class RecommendationCubit extends Cubit<RecommendationState> {
  final GetProductRecommendations getProductRecommendations;
  final GetServiceRecommendations getServiceRecommendations;
  final GetAccommodationRecommendations getAccommodationRecommendations;

  RecommendationCubit({
    required this.getProductRecommendations,
    required this.getServiceRecommendations,
    required this.getAccommodationRecommendations,
  }) : super(RecommendationInitial());

  /// Load product recommendations
  Future<void> loadProductRecommendations({
    required String currentProductId,
    RecommendationCriteriaEntity? criteria,
  }) async {
    if (isClosed) return;
    emit(RecommendationsLoading());

    final result = await getProductRecommendations(
      currentProductId: currentProductId,
      criteria: criteria,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(RecommendationError(message: failure.message)),
      (recommendations) =>
          emit(RecommendationsLoaded(recommendations: recommendations)),
    );
  }

  /// Load service recommendations
  Future<void> loadServiceRecommendations({
    required String currentServiceId,
    RecommendationCriteriaEntity? criteria,
  }) async {
    if (isClosed) return;
    emit(RecommendationsLoading());

    final result = await getServiceRecommendations(
      currentServiceId: currentServiceId,
      criteria: criteria,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(RecommendationError(message: failure.message)),
      (recommendations) =>
          emit(RecommendationsLoaded(recommendations: recommendations)),
    );
  }

  /// Load accommodation recommendations
  Future<void> loadAccommodationRecommendations({
    required String currentAccommodationId,
    RecommendationCriteriaEntity? criteria,
  }) async {
    if (isClosed) return;
    emit(RecommendationsLoading());

    final result = await getAccommodationRecommendations(
      currentAccommodationId: currentAccommodationId,
      criteria: criteria,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(RecommendationError(message: failure.message)),
      (recommendations) =>
          emit(RecommendationsLoaded(recommendations: recommendations)),
    );
  }

  /// Load recommendations based on type
  Future<void> loadRecommendations({
    required String currentItemId,
    required RecommendationType type,
    RecommendationCriteriaEntity? criteria,
  }) async {
    switch (type) {
      case RecommendationType.product:
        await loadProductRecommendations(
          currentProductId: currentItemId,
          criteria: criteria,
        );
        break;
      case RecommendationType.service:
        await loadServiceRecommendations(
          currentServiceId: currentItemId,
          criteria: criteria,
        );
        break;
      case RecommendationType.accommodation:
        await loadAccommodationRecommendations(
          currentAccommodationId: currentItemId,
          criteria: criteria,
        );
        break;
    }
  }
}
