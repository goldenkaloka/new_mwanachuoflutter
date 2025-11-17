import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/promotions/domain/usecases/get_active_promotions.dart';
import 'package:mwanachuo/features/promotions/presentation/bloc/promotion_state.dart';

class PromotionCubit extends Cubit<PromotionState> {
  final GetActivePromotions getActivePromotions;

  PromotionCubit({required this.getActivePromotions})
    : super(PromotionInitial());

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
}
