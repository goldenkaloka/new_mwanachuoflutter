import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/promotions/data/models/promotion_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class PromotionRemoteDataSource {
  Future<List<PromotionModel>> getActivePromotions();
  Future<PromotionModel> getPromotionById(String promotionId);
  Future<PromotionModel> createPromotion({
    required String title,
    required String subtitle,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    String? imageUrl,
    String? targetUrl,
  });
}

class PromotionRemoteDataSourceImpl implements PromotionRemoteDataSource {
  final SupabaseClient supabaseClient;

  PromotionRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<PromotionModel>> getActivePromotions() async {
    try {
      final now = DateTime.now().toIso8601String();

      final response = await supabaseClient
          .from(DatabaseConstants.promotionsTable)
          .select()
          .eq('is_active', true)
          .lte('start_date', now)
          .gte('end_date', now)
          .order('created_at', ascending: false);

      return (response as List).map((json) => PromotionModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get active promotions: $e');
    }
  }

  @override
  Future<PromotionModel> getPromotionById(String promotionId) async {
    try {
      final response = await supabaseClient
          .from(DatabaseConstants.promotionsTable)
          .select()
          .eq('id', promotionId)
          .single();

      return PromotionModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get promotion: $e');
    }
  }

  @override
  Future<PromotionModel> createPromotion({
    required String title,
    required String subtitle,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    String? imageUrl,
    String? targetUrl,
  }) async {
    try {
      final response = await supabaseClient
          .from(DatabaseConstants.promotionsTable)
          .insert({
            'title': title,
            'subtitle': subtitle,
            'description': description,
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
            'image_url': imageUrl,
            'target_url': targetUrl,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return PromotionModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to create promotion: $e');
    }
  }
}

