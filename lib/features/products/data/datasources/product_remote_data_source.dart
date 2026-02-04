import 'package:flutter/foundation.dart';
import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/models/filter_model.dart';
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
    ProductFilter? filter,
  });

  /// Get product by ID
  Future<ProductModel> getProductById(String productId);

  /// Get user's products
  Future<List<ProductModel>> getMyProducts({
    int? limit,
    int? offset,
    ProductFilter? filter,
  });

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
    double? oldPrice,
    bool isGlobal = false,
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
    double? oldPrice,
    bool? isGlobal,
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
    ProductFilter? filter,
  }) async {
    try {
      dynamic queryBuilder = supabaseClient
          .from(DatabaseConstants.productsTable)
          .select('*, users!inner(full_name, avatar_url, phone_number)')
          .eq('is_active', true);

      // Apply individual parameters first (always apply these)
      if (category != null) {
        queryBuilder = queryBuilder.eq('category', category);
      }

      if (universityId != null) {
        // Show products that match the university OR are global (empty university_ids)
        queryBuilder = queryBuilder.or(
          'university_ids.cs.{"$universityId"},university_ids.eq.{}',
        );
      }

      if (sellerId != null) {
        queryBuilder = queryBuilder.eq('seller_id', sellerId);
      }

      if (isFeatured != null && isFeatured) {
        queryBuilder = queryBuilder.eq('is_featured', true);
      }

      // Apply filters from ProductFilter object
      if (filter != null) {
        // Text search
        if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
          final searchTerm = filter.searchQuery!.trim();
          debugPrint('🔍 Searching products with query: "$searchTerm"');
          // Use or() with proper PostgREST syntax: column.operator.value,column.operator.value
          // The format is: column.operator.value,column.operator.value
          queryBuilder = queryBuilder.or(
            'title.ilike.%$searchTerm%,description.ilike.%$searchTerm%',
          );
          debugPrint('✅ Search filter applied to query');
        }

        // Price range
        if (filter.minPrice != null) {
          queryBuilder = queryBuilder.gte('price', filter.minPrice!);
        }
        if (filter.maxPrice != null) {
          queryBuilder = queryBuilder.lte('price', filter.maxPrice!);
        }

        // Category filter (only if not already set by individual parameter)
        if (filter.category != null &&
            filter.category!.isNotEmpty &&
            category == null) {
          queryBuilder = queryBuilder.eq('category', filter.category!);
        }

        // Condition filter
        if (filter.condition != null && filter.condition!.isNotEmpty) {
          queryBuilder = queryBuilder.eq('condition', filter.condition!);
        }

        // Location filter
        if (filter.location != null && filter.location!.isNotEmpty) {
          queryBuilder = queryBuilder.ilike('location', '%${filter.location}%');
        }

        // Apply sorting
        if (filter.sortBy != null) {
          if (filter.sortBy == 'popularity') {
            queryBuilder = queryBuilder
                .order('view_count', ascending: false)
                .order('rating', ascending: false);
          } else if (filter.sortBy == 'price_asc') {
            queryBuilder = queryBuilder.order('price', ascending: true);
          } else if (filter.sortBy == 'price_desc') {
            queryBuilder = queryBuilder.order('price', ascending: false);
          } else {
            queryBuilder = queryBuilder.order(
              filter.sortBy!,
              ascending: filter.sortAscending,
            );
          }
        } else {
          // Default sort by created_at
          queryBuilder = queryBuilder.order('created_at', ascending: false);
        }
      } else {
        // Default sort by created_at if no filter
        queryBuilder = queryBuilder.order('created_at', ascending: false);
      }

      final finalQuery = queryBuilder;

      final response = await finalQuery
          .limit(limit ?? 20)
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 20) - 1);

      return (response as List)
          .map(
            (json) => ProductModel.fromJson({
              ...json,
              'seller_name': json['users']['full_name'],
              'seller_phone': json['users']['phone_number'],
              'seller_avatar': json['users']['avatar_url'],
            }),
          )
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
          .select('*, users!inner(full_name, avatar_url, phone_number)')
          .eq('id', productId)
          .single();

      return ProductModel.fromJson({
        ...response,
        'seller_name': response['users']['full_name'],
        'seller_phone': response['users']['phone_number'],
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
    ProductFilter? filter,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('User not authenticated');
      }

      dynamic queryBuilder = supabaseClient
          .from(DatabaseConstants.productsTable)
          .select('*, users!inner(full_name, avatar_url, phone_number)')
          .eq('seller_id', currentUser.id);

      // Apply filters from ProductFilter object
      if (filter != null) {
        // Text search
        if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
          final searchTerm = filter.searchQuery!.trim();
          debugPrint('🔍 Searching products with query: "$searchTerm"');
          // Use or() with proper PostgREST syntax: column.operator.value,column.operator.value
          // The format is: column.operator.value,column.operator.value
          queryBuilder = queryBuilder.or(
            'title.ilike.%$searchTerm%,description.ilike.%$searchTerm%',
          );
          debugPrint('✅ Search filter applied to query');
        }

        // Price range
        if (filter.minPrice != null) {
          queryBuilder = queryBuilder.gte('price', filter.minPrice!);
        }
        if (filter.maxPrice != null) {
          queryBuilder = queryBuilder.lte('price', filter.maxPrice!);
        }

        // Category filter
        if (filter.category != null && filter.category!.isNotEmpty) {
          queryBuilder = queryBuilder.eq('category', filter.category!);
        }

        // Condition filter
        if (filter.condition != null && filter.condition!.isNotEmpty) {
          queryBuilder = queryBuilder.eq('condition', filter.condition!);
        }

        // Location filter
        if (filter.location != null && filter.location!.isNotEmpty) {
          queryBuilder = queryBuilder.ilike('location', '%${filter.location}%');
        }

        // Apply sorting
        if (filter.sortBy != null) {
          if (filter.sortBy == 'popularity') {
            queryBuilder = queryBuilder
                .order('view_count', ascending: false)
                .order('rating', ascending: false);
          } else if (filter.sortBy == 'price_asc') {
            queryBuilder = queryBuilder.order('price', ascending: true);
          } else if (filter.sortBy == 'price_desc') {
            queryBuilder = queryBuilder.order('price', ascending: false);
          } else {
            queryBuilder = queryBuilder.order(
              filter.sortBy!,
              ascending: filter.sortAscending,
            );
          }
        } else {
          queryBuilder = queryBuilder.order('created_at', ascending: false);
        }
      } else {
        queryBuilder = queryBuilder.order('created_at', ascending: false);
      }

      final response = await queryBuilder
          .limit(limit ?? 20)
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 20) - 1);

      return (response as List)
          .map(
            (json) => ProductModel.fromJson({
              ...json,
              'seller_name': json['users']['full_name'],
              'seller_phone': json['users']['phone_number'],
              'seller_avatar': json['users']['avatar_url'],
            }),
          )
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
    double? oldPrice,
    bool isGlobal = false,
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
        'create_product_atomic',
        params: {
          'p_title': title,
          'p_description': description,
          'p_price': price,
          'p_category': category,
          'p_condition': condition,
          'p_images': imageUrls,
          'p_seller_id': currentUser.id,
          'p_location': location,
          'p_university_ids':
              [], // Handled by backend if needed, but parameter is required
          'p_is_global': isGlobal,
          'p_metadata': {...?metadata, 'old_price': oldPrice}
            ..removeWhere((_, value) => value == null),
        },
      );

      final dynamic responseData = result;
      final productId = responseData['id'] as String;
      debugPrint('✅ Product created with ID: $productId');
      debugPrint('📢 Notifications sent to users with matching universities');

      // Fetch the created product with user details
      final response = await supabaseClient
          .from(DatabaseConstants.productsTable)
          .select('*, users!inner(full_name, avatar_url, phone_number)')
          .eq('id', productId)
          .single();

      return ProductModel.fromJson({
        ...response,
        'seller_name': response['users']['full_name'],
        'seller_phone': response['users']['phone_number'],
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
    double? oldPrice,
    bool? isGlobal,
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
      if (isGlobal != null) {
        // When updating global status, we always reset university_ids
        // For now, turning global OFF also resets it (needs enhancement later)
        updateData['university_ids'] = [];
      }

      final finalMetadata = {...?metadata, 'old_price': oldPrice}
        ..removeWhere((_, value) => value == null);
      if (finalMetadata.isNotEmpty) updateData['metadata'] = finalMetadata;

      final response = await supabaseClient
          .from(DatabaseConstants.productsTable)
          .update(updateData)
          .eq('id', productId)
          .eq('seller_id', currentUser.id)
          .select('*, users!inner(full_name, avatar_url, phone_number)')
          .single();

      return ProductModel.fromJson({
        ...response,
        'seller_name': response['users']['full_name'],
        'seller_phone': response['users']['phone_number'],
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
      await supabaseClient.rpc(
        'increment_product_views',
        params: {'product_id': productId},
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to increment view count: $e');
    }
  }
}
