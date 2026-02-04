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
    List<String>? terms,
    String type = 'banner',
    String? videoUrl,
    int priority = 0,
    String buttonText = 'Shop Now',
    String? userId,
    String? externalLink,
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
          .select('*, users(full_name, phone_number)')
          .eq('is_active', true)
          .lte('start_date', now)
          .gte('end_date', now)
          .order('priority', ascending: false)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PromotionModel.fromJson(json))
          .toList();
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
          .select('*, users(full_name, phone_number)')
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
    List<String>? terms,
    String type = 'banner',
    String? videoUrl,
    int priority = 0,
    String buttonText = 'Shop Now',
    String? userId,
    String? externalLink,
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
            'terms': terms,
            'type': type,
            'video_url': videoUrl,
            'priority': priority,
            'button_text': buttonText,
            'user_id': userId,
            'external_link': externalLink,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('*, users(full_name, phone_number)')
          .single();

      return PromotionModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to create promotion: $e');
    }
  }
}
