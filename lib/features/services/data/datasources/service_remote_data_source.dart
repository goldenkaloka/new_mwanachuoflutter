import 'package:flutter/foundation.dart';
import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/services/data/models/service_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ServiceRemoteDataSource {
  Future<List<ServiceModel>> getServices({
    String? category,
    String? universityId,
    String? providerId,
    bool? isFeatured,
    int? limit,
    int? offset,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    String? location,
    String? sortBy,
    bool sortAscending = true,
  });
  Future<ServiceModel> getServiceById(String serviceId);
  Future<List<ServiceModel>> getMyServices({int? limit, int? offset});
  Future<ServiceModel> createService({
    required String title,
    required String description,
    required double price,
    required String category,
    required String priceType,
    required List<String> imageUrls,
    required String location,
    required String contactPhone,
    String? contactEmail,
    required List<String> availability,
    Map<String, dynamic>? metadata,
    bool isGlobal = false,
  });
  Future<ServiceModel> updateService({
    required String serviceId,
    String? title,
    String? description,
    double? price,
    String? category,
    String? priceType,
    List<String>? imageUrls,
    String? location,
    String? contactPhone,
    String? contactEmail,
    List<String>? availability,
    bool? isActive,
    Map<String, dynamic>? metadata,
    bool? isGlobal,
  });
  Future<void> deleteService(String serviceId);
  Future<void> incrementViewCount(String serviceId);
}

class ServiceRemoteDataSourceImpl implements ServiceRemoteDataSource {
  final SupabaseClient supabaseClient;

  ServiceRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<ServiceModel>> getServices({
    String? category,
    String? universityId,
    String? providerId,
    bool? isFeatured,
    int? limit,
    int? offset,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    String? location,
    String? sortBy,
    bool sortAscending = true,
  }) async {
    try {
      var queryBuilder = supabaseClient
          .from(DatabaseConstants.servicesTable)
          .select('*, users!inner(full_name, avatar_url)')
          .eq('is_active', true);

      if (category != null) {
        queryBuilder = queryBuilder.eq('category', category);
      }
      if (universityId != null) {
        queryBuilder = queryBuilder.or(
          'university_ids.cs.{"$universityId"},university_ids.eq.{}',
        );
      }
      if (providerId != null) {
        queryBuilder = queryBuilder.eq('provider_id', providerId);
      }
      if (isFeatured == true) {
        queryBuilder = queryBuilder.eq('is_featured', true);
      }

      // Text search
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryBuilder = queryBuilder.or(
          'title.ilike.%$searchQuery%,description.ilike.%$searchQuery%',
        );
      }

      // Price range
      if (minPrice != null) {
        queryBuilder = queryBuilder.gte('price', minPrice);
      }
      if (maxPrice != null) {
        queryBuilder = queryBuilder.lte('price', maxPrice);
      }

      // Location filter
      if (location != null && location.isNotEmpty) {
        queryBuilder = queryBuilder.ilike('location', '%$location%');
      }

      // Sorting
      dynamic finalQuery;
      if (sortBy != null) {
        if (sortBy == 'popularity') {
          finalQuery = queryBuilder
              .order('view_count', ascending: false)
              .order('rating', ascending: false);
        } else {
          finalQuery = queryBuilder.order(sortBy, ascending: sortAscending);
        }
      } else {
        finalQuery = queryBuilder.order('created_at', ascending: false);
      }

      final response = await finalQuery
          .limit(limit ?? 20)
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 20) - 1);

      return (response as List)
          .map(
            (json) => ServiceModel.fromJson({
              ...json,
              'provider_name': json['users']['full_name'],
              'provider_avatar': json['users']['avatar_url'],
            }),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get services: $e');
    }
  }

  @override
  Future<ServiceModel> getServiceById(String serviceId) async {
    try {
      final response = await supabaseClient
          .from(DatabaseConstants.servicesTable)
          .select('*, users!inner(full_name, avatar_url)')
          .eq('id', serviceId)
          .single();

      return ServiceModel.fromJson({
        ...response,
        'provider_name': response['users']['full_name'],
        'provider_avatar': response['users']['avatar_url'],
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get service: $e');
    }
  }

  @override
  Future<List<ServiceModel>> getMyServices({int? limit, int? offset}) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      final response = await supabaseClient
          .from(DatabaseConstants.servicesTable)
          .select('*, users!inner(full_name, avatar_url)')
          .eq('provider_id', currentUser.id)
          .order('created_at', ascending: false)
          .limit(limit ?? 20)
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 20) - 1);

      return (response as List)
          .map(
            (json) => ServiceModel.fromJson({
              ...json,
              'provider_name': json['users']['full_name'],
              'provider_avatar': json['users']['avatar_url'],
            }),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get my services: $e');
    }
  }

  @override
  Future<ServiceModel> createService({
    required String title,
    required String description,
    required double price,
    required String category,
    required String priceType,
    required List<String> imageUrls,
    required String location,
    required String contactPhone,
    String? contactEmail,
    required List<String> availability,
    Map<String, dynamic>? metadata,
    bool isGlobal = false,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      debugPrint('💾 Creating service with multi-university transaction...');
      debugPrint('👤 Provider ID: ${currentUser.id}');
      debugPrint('📝 Title: $title');

      // Use transaction function to create service with all user's universities
      // This will also send notifications to users with matching universities
      final result = await supabaseClient.rpc(
        'create_service_with_universities',
        params: {
          'p_title': title,
          'p_description': description,
          'p_price': price,
          'p_category': category,
          'p_price_type': priceType,
          'p_images': imageUrls,
          'p_provider_id': currentUser.id,
          'p_location': location,
          'p_contact_phone': contactPhone,
          'p_contact_email': contactEmail,
          'p_availability': availability,
          'p_metadata': metadata,
          'p_is_global': isGlobal,
        },
      );

      final serviceId = result as String;
      debugPrint('✅ Service created with ID: $serviceId');
      debugPrint('📢 Notifications sent to users with matching universities');

      // Fetch the created service with user details
      final response = await supabaseClient
          .from(DatabaseConstants.servicesTable)
          .select('*, users!inner(full_name, avatar_url)')
          .eq('id', serviceId)
          .single();

      return ServiceModel.fromJson({
        ...response,
        'provider_name': response['users']['full_name'],
        'provider_avatar': response['users']['avatar_url'],
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to create service: $e');
    }
  }

  @override
  Future<ServiceModel> updateService({
    required String serviceId,
    String? title,
    String? description,
    double? price,
    String? category,
    String? priceType,
    List<String>? imageUrls,
    String? location,
    String? contactPhone,
    String? contactEmail,
    List<String>? availability,
    bool? isActive,
    Map<String, dynamic>? metadata,
    bool? isGlobal,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (category != null) updateData['category'] = category;
      if (priceType != null) updateData['price_type'] = priceType;
      if (imageUrls != null) updateData['images'] = imageUrls;
      if (location != null) updateData['location'] = location;
      if (contactPhone != null) updateData['contact_phone'] = contactPhone;
      if (contactEmail != null) updateData['contact_email'] = contactEmail;
      if (availability != null) updateData['availability'] = availability;
      if (isActive != null) updateData['is_active'] = isActive;
      if (isGlobal != null) updateData['is_global'] = isGlobal;
      if (metadata != null) updateData['metadata'] = metadata;

      final response = await supabaseClient
          .from(DatabaseConstants.servicesTable)
          .update(updateData)
          .eq('id', serviceId)
          .eq('provider_id', currentUser.id)
          .select('*, users!inner(full_name, avatar_url)')
          .single();

      return ServiceModel.fromJson({
        ...response,
        'provider_name': response['users']['full_name'],
        'provider_avatar': response['users']['avatar_url'],
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to update service: $e');
    }
  }

  @override
  Future<void> deleteService(String serviceId) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      await supabaseClient
          .from(DatabaseConstants.servicesTable)
          .delete()
          .eq('id', serviceId)
          .eq('provider_id', currentUser.id);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to delete service: $e');
    }
  }

  @override
  Future<void> incrementViewCount(String serviceId) async {
    try {
      await supabaseClient.rpc(
        'increment_service_views',
        params: {'service_id': serviceId},
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to increment view count: $e');
    }
  }
}
