import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/promotions/domain/usecases/create_promotion.dart';
import 'package:mwanachuo/features/promotions/domain/usecases/get_active_promotions.dart';
import 'package:mwanachuo/features/promotions/presentation/bloc/promotion_state.dart';

class PromotionCubit extends Cubit<PromotionState> {
  final GetActivePromotions getActivePromotions;
  final CreatePromotion createPromotion;

  PromotionCubit({
    required this.getActivePromotions,
    required this.createPromotion,
  }) : super(PromotionInitial());

  Future<void> loadActivePromotions() async {
    if (isClosed) return;

    // Prevent reloading if already loading
    if (state is PromotionsLoading) {
      debugPrint('⏭️  Promotions already loading, skipping...');
      return;
    }

    debugPrint('🎉 Loading promotions...');
    emit(PromotionsLoading());

    final result = await getActivePromotions(NoParams());

    if (isClosed) return;
    result.fold(
      (failure) {
        debugPrint('❌ Promotions load failed: ${failure.message}');
        emit(PromotionError(message: failure.message));
      },
      (promotions) {
        debugPrint('✅ Promotions loaded: ${promotions.length} items');
        emit(PromotionsLoaded(promotions: promotions));
      },
    );
  }

  Future<void> createNewPromotion({
    required String title,
    required String subtitle,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    File? image,
    String? targetUrl,
    List<String>? terms,
  }) async {
    if (isClosed) return;

    emit(PromotionsLoading());

    final result = await createPromotion(
      CreatePromotionParams(
        title: title,
        subtitle: subtitle,
        description: description,
        startDate: startDate,
        endDate: endDate,
        image: image,
        targetUrl: targetUrl,
        terms: terms,
      ),
    );

    if (isClosed) return;
    result.fold(
      (failure) {
        debugPrint('❌ Promotion creation failed: ${failure.message}');
        emit(PromotionError(message: failure.message));
      },
      (promotion) {
        debugPrint('✅ Promotion created successfully: ${promotion.title}');
        debugPrint('   Start Date: ${promotion.startDate}');
        debugPrint('   End Date: ${promotion.endDate}');
        debugPrint('   Is Active: ${promotion.isActive}');

        // Emit PromotionCreated state
        emit(PromotionCreated(promotion: promotion));

        // Reload promotions to include the new one
        loadActivePromotions();
      },
    );
  }
}
