import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/shared/categories/data/models/category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract class defining category remote data source operations
abstract class CategoryRemoteDataSource {
  /// Get all active product categories
  Future<List<ProductCategoryModel>> getProductCategories();

  /// Get all active product conditions
  Future<List<ProductConditionModel>> getProductConditions();
}

/// Implementation of CategoryRemoteDataSource using Supabase
class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final SupabaseClient supabaseClient;

  CategoryRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<ProductCategoryModel>> getProductCategories() async {
    try {
      final response = await supabaseClient
          .from('product_categories')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      return (response as List)
          .map((json) => ProductCategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get product categories: $e');
    }
  }

  @override
  Future<List<ProductConditionModel>> getProductConditions() async {
    try {
      final response = await supabaseClient
          .from('product_conditions')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      return (response as List)
          .map((json) => ProductConditionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get product conditions: $e');
    }
  }
}

