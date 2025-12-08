import 'package:flutter/foundation.dart';
import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/accommodations/data/models/accommodation_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AccommodationRemoteDataSource {
  Future<List<AccommodationModel>> getAccommodations({
    String? roomType,
    String? universityId,
    String? ownerId,
    bool? isFeatured,
    int? limit,
    int? offset,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    String? location,
    List<String>? amenities,
    String? priceType,
    String? sortBy,
    bool sortAscending = true,
  });
  Future<AccommodationModel> getAccommodationById(String accommodationId);
  Future<List<AccommodationModel>> getMyAccommodations({int? limit, int? offset});
  Future<AccommodationModel> createAccommodation({
    required String name,
    required String description,
    required double price,
    required String priceType,
    required String roomType,
    required List<String> imageUrls,
    required String location,
    required String contactPhone,
    String? contactEmail,
    required List<String> amenities,
    required int bedrooms,
    required int bathrooms,
    Map<String, dynamic>? metadata,
  });
  Future<AccommodationModel> updateAccommodation({
    required String accommodationId,
    String? name,
    String? description,
    double? price,
    String? priceType,
    String? roomType,
    List<String>? imageUrls,
    String? location,
    String? contactPhone,
    String? contactEmail,
    List<String>? amenities,
    int? bedrooms,
    int? bathrooms,
    bool? isActive,
    Map<String, dynamic>? metadata,
  });
  Future<void> deleteAccommodation(String accommodationId);
  Future<void> incrementViewCount(String accommodationId);
}

class AccommodationRemoteDataSourceImpl implements AccommodationRemoteDataSource {
  final SupabaseClient supabaseClient;

  AccommodationRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<AccommodationModel>> getAccommodations({
    String? roomType,
    String? universityId,
    String? ownerId,
    bool? isFeatured,
    int? limit,
    int? offset,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    String? location,
    List<String>? amenities,
    String? priceType,
    String? sortBy,
    bool sortAscending = true,
  }) async {
    try {
      var queryBuilder = supabaseClient
          .from(DatabaseConstants.accommodationsTable)
          .select('*, users!inner(full_name, avatar_url)')
          .eq('is_active', true);

      if (roomType != null) queryBuilder = queryBuilder.eq('room_type', roomType);
      if (universityId != null) queryBuilder = queryBuilder.eq('university_id', universityId);
      if (ownerId != null) queryBuilder = queryBuilder.eq('owner_id', ownerId);
      if (isFeatured == true) queryBuilder = queryBuilder.eq('is_featured', true);

      // Text search
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryBuilder = queryBuilder.or(
          'name.ilike.%$searchQuery%,description.ilike.%$searchQuery%',
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

      // Price type filter
      if (priceType != null && priceType.isNotEmpty) {
        queryBuilder = queryBuilder.eq('price_type', priceType);
      }

      // Amenities filter (check if amenities array contains any of the selected amenities)
      if (amenities != null && amenities.isNotEmpty) {
        // Use overlaps to check if any amenity in the filter matches amenities in the database
        for (final amenity in amenities) {
          queryBuilder = queryBuilder.contains('amenities', [amenity]);
        }
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
          .map((json) => AccommodationModel.fromJson({
                ...json,
                'owner_name': json['users']['full_name'],
                'owner_avatar': json['users']['avatar_url'],
              }))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get accommodations: $e');
    }
  }

  @override
  Future<AccommodationModel> getAccommodationById(String accommodationId) async {
    try {
      final response = await supabaseClient
          .from(DatabaseConstants.accommodationsTable)
          .select('*, users!inner(full_name, avatar_url)')
          .eq('id', accommodationId)
          .single();

      return AccommodationModel.fromJson({
        ...response,
        'owner_name': response['users']['full_name'],
        'owner_avatar': response['users']['avatar_url'],
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get accommodation: $e');
    }
  }

  @override
  Future<List<AccommodationModel>> getMyAccommodations({int? limit, int? offset}) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      final response = await supabaseClient
          .from(DatabaseConstants.accommodationsTable)
          .select('*, users!inner(full_name, avatar_url)')
          .eq('owner_id', currentUser.id)
          .order('created_at', ascending: false)
          .limit(limit ?? 20)
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 20) - 1);

      return (response as List)
          .map((json) => AccommodationModel.fromJson({
                ...json,
                'owner_name': json['users']['full_name'],
                'owner_avatar': json['users']['avatar_url'],
              }))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get my accommodations: $e');
    }
  }

  @override
  Future<AccommodationModel> createAccommodation({
    required String name,
    required String description,
    required double price,
    required String priceType,
    required String roomType,
    required List<String> imageUrls,
    required String location,
    required String contactPhone,
    String? contactEmail,
    required List<String> amenities,
    required int bedrooms,
    required int bathrooms,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      debugPrint('💾 Creating accommodation with multi-university transaction...');
      debugPrint('👤 Owner ID: ${currentUser.id}');
      debugPrint('📝 Name: $name');
      
      // Use transaction function to create accommodation with all user's universities
      // This will also send notifications to users with matching universities
      final result = await supabaseClient.rpc(
        'create_accommodation_with_universities',
        params: {
          'p_name': name,
          'p_description': description,
          'p_price': price,
          'p_price_type': priceType,
          'p_room_type': roomType,
          'p_images': imageUrls,
          'p_owner_id': currentUser.id,
          'p_location': location,
          'p_contact_phone': contactPhone,
          'p_contact_email': contactEmail,
          'p_amenities': amenities,
          'p_bedrooms': bedrooms,
          'p_bathrooms': bathrooms,
          'p_metadata': metadata,
        },
      );

      final accommodationId = result as String;
      debugPrint('✅ Accommodation created with ID: $accommodationId');
      debugPrint('📢 Notifications sent to users with matching universities');

      // Fetch the created accommodation with user details
      final response = await supabaseClient
          .from(DatabaseConstants.accommodationsTable)
          .select('*, users!inner(full_name, avatar_url)')
          .eq('id', accommodationId)
          .single();

      return AccommodationModel.fromJson({
        ...response,
        'owner_name': response['users']['full_name'],
        'owner_avatar': response['users']['avatar_url'],
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to create accommodation: $e');
    }
  }

  @override
  Future<AccommodationModel> updateAccommodation({
    required String accommodationId,
    String? name,
    String? description,
    double? price,
    String? priceType,
    String? roomType,
    List<String>? imageUrls,
    String? location,
    String? contactPhone,
    String? contactEmail,
    List<String>? amenities,
    int? bedrooms,
    int? bathrooms,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      final updateData = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (priceType != null) updateData['price_type'] = priceType;
      if (roomType != null) updateData['room_type'] = roomType;
      if (imageUrls != null) updateData['images'] = imageUrls;
      if (location != null) updateData['location'] = location;
      if (contactPhone != null) updateData['contact_phone'] = contactPhone;
      if (contactEmail != null) updateData['contact_email'] = contactEmail;
      if (amenities != null) updateData['amenities'] = amenities;
      if (bedrooms != null) updateData['bedrooms'] = bedrooms;
      if (bathrooms != null) updateData['bathrooms'] = bathrooms;
      if (isActive != null) updateData['is_active'] = isActive;
      if (metadata != null) updateData['metadata'] = metadata;

      final response = await supabaseClient
          .from(DatabaseConstants.accommodationsTable)
          .update(updateData)
          .eq('id', accommodationId)
          .eq('owner_id', currentUser.id)
          .select('*, users!inner(full_name, avatar_url)')
          .single();

      return AccommodationModel.fromJson({
        ...response,
        'owner_name': response['users']['full_name'],
        'owner_avatar': response['users']['avatar_url'],
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to update accommodation: $e');
    }
  }

  @override
  Future<void> deleteAccommodation(String accommodationId) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      await supabaseClient
          .from(DatabaseConstants.accommodationsTable)
          .delete()
          .eq('id', accommodationId)
          .eq('owner_id', currentUser.id);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to delete accommodation: $e');
    }
  }

  @override
  Future<void> incrementViewCount(String accommodationId) async {
    try {
      await supabaseClient.rpc('increment_accommodation_views', params: {
        'accommodation_id': accommodationId,
      });
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to increment view count: $e');
    }
  }
}

