import 'package:flutter/foundation.dart';
import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/products/data/models/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract class defining product remote data source operations
abstract class ProductRemoteDataSource {
  /// Get products
  Future<List<ProductModel>> getProducts({
    String? category,
    String? universityId,
    String? sellerId,
    bool? isFeatured,
    int? limit,
    int? offset,
  });

  /// Get product by ID
  Future<ProductModel> getProductById(String productId);

  /// Get user's products
  Future<List<ProductModel>> getMyProducts({int? limit, int? offset});

  /// Create product
  Future<ProductModel> createProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    required List<String> imageUrls,
    required String location,
    Map<String, dynamic>? metadata,
  });

  /// Update product
  Future<ProductModel> updateProduct({
    required String productId,
    String? title,
    String? description,
    double? price,
    String? category,
    String? condition,
    List<String>? imageUrls,
    String? location,
    bool? isActive,
    Map<String, dynamic>? metadata,
  });

  /// Delete product
  Future<void> deleteProduct(String productId);

  /// Increment view count
  Future<void> incrementViewCount(String productId);
}

/// Implementation of ProductRemoteDataSource using Supabase
class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final SupabaseClient supabaseClient;

  ProductRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<ProductModel>> getProducts({
    String? category,
    String? universityId,
    String? sellerId,
    bool? isFeatured,
    int? limit,
    int? offset,
  }) async {
    try {
      var queryBuilder = supabaseClient
          .from(DatabaseConstants.productsTable)
          .select('*, users!inner(full_name, avatar_url)')
          .eq('is_active', true);

      if (category != null) {
        queryBuilder = queryBuilder.eq('category', category);
      }

      if (universityId != null) {
        queryBuilder = queryBuilder.eq('university_id', universityId);
      }

      if (sellerId != null) {
        queryBuilder = queryBuilder.eq('seller_id', sellerId);
      }

      if (isFeatured != null && isFeatured) {
        queryBuilder = queryBuilder.eq('is_featured', true);
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .limit(limit ?? 20)
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 20) - 1);

      return (response as List)
          .map((json) => ProductModel.fromJson({
                ...json,
                'seller_name': json['users']['full_name'],
                'seller_avatar': json['users']['avatar_url'],
              }))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get products: $e');
    }
  }

  @override
  Future<ProductModel> getProductById(String productId) async {
    try {
      final response = await supabaseClient
          .from(DatabaseConstants.productsTable)
          .select('*, users!inner(full_name, avatar_url)')
          .eq('id', productId)
          .single();

      return ProductModel.fromJson({
        ...response,
        'seller_name': response['users']['full_name'],
        'seller_avatar': response['users']['avatar_url'],
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get product: $e');
    }
  }

  @override
  Future<List<ProductModel>> getMyProducts({
    int? limit,
    int? offset,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      final response = await supabaseClient
          .from(DatabaseConstants.productsTable)
          .select('*, users!inner(full_name, avatar_url)')
          .eq('seller_id', currentUser.id)
          .order('created_at', ascending: false)
          .limit(limit ?? 20)
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 20) - 1);

      return (response as List)
          .map((json) => ProductModel.fromJson({
                ...json,
                'seller_name': json['users']['full_name'],
                'seller_avatar': json['users']['avatar_url'],
              }))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get my products: $e');
    }
  }

  @override
  Future<ProductModel> createProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    required List<String> imageUrls,
    required String location,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      debugPrint('💾 Creating product with multi-university transaction...');
      debugPrint('👤 Seller ID: ${currentUser.id}');
      debugPrint('📝 Title: $title');
      debugPrint('📷 Images: ${imageUrls.length}');
      
      // Use transaction function to create product with all user's universities
      // This will also send notifications to users with matching universities
      final result = await supabaseClient.rpc(
        'create_product_with_universities',
        params: {
          'p_title': title,
          'p_description': description,
          'p_price': price,
          'p_category': category,
          'p_condition': condition,
          'p_images': imageUrls,
          'p_seller_id': currentUser.id,
          'p_location': location,
          'p_metadata': metadata,
        },
      );

      final productId = result as String;
      debugPrint('✅ Product created with ID: $productId');
      debugPrint('📢 Notifications sent to users with matching universities');

      // Fetch the created product with user details
      final response = await supabaseClient
          .from(DatabaseConstants.productsTable)
          .select('*, users!inner(full_name, avatar_url)')
          .eq('id', productId)
          .single();

      return ProductModel.fromJson({
        ...response,
        'seller_name': response['users']['full_name'],
        'seller_avatar': response['users']['avatar_url'],
      });
    } on PostgrestException catch (e) {
      debugPrint('❌ PostgrestException: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      debugPrint('❌ Failed to create product: $e');
      throw ServerException('Failed to create product: $e');
    }
  }

  @override
  Future<ProductModel> updateProduct({
    required String productId,
    String? title,
    String? description,
    double? price,
    String? category,
    String? condition,
    List<String>? imageUrls,
    String? location,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (category != null) updateData['category'] = category;
      if (condition != null) updateData['condition'] = condition;
      if (imageUrls != null) updateData['images'] = imageUrls;
      if (location != null) updateData['location'] = location;
      if (isActive != null) updateData['is_active'] = isActive;
      if (metadata != null) updateData['metadata'] = metadata;

      final response = await supabaseClient
          .from(DatabaseConstants.productsTable)
          .update(updateData)
          .eq('id', productId)
          .eq('seller_id', currentUser.id)
          .select('*, users!inner(full_name, avatar_url)')
          .single();

      return ProductModel.fromJson({
        ...response,
        'seller_name': response['users']['full_name'],
        'seller_avatar': response['users']['avatar_url'],
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to update product: $e');
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      await supabaseClient
          .from(DatabaseConstants.productsTable)
          .delete()
          .eq('id', productId)
          .eq('seller_id', currentUser.id);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to delete product: $e');
    }
  }

  @override
  Future<void> incrementViewCount(String productId) async {
    try {
      await supabaseClient.rpc('increment_product_views', params: {
        'product_id': productId,
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to increment view count: $e');
    }
  }
}

