import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/shared/recommendations/data/models/recommendation_model.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_criteria_entity.dart';
import 'package:mwanachuo/features/shared/recommendations/domain/entities/recommendation_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract class defining recommendation remote data source operations
abstract class RecommendationRemoteDataSource {
  Future<List<RecommendationModel>> getProductRecommendations({
    required String currentProductId,
    RecommendationCriteriaEntity? criteria,
  });

  Future<List<RecommendationModel>> getServiceRecommendations({
    required String currentServiceId,
    RecommendationCriteriaEntity? criteria,
  });

  Future<List<RecommendationModel>> getAccommodationRecommendations({
    required String currentAccommodationId,
    RecommendationCriteriaEntity? criteria,
  });
}

/// Implementation of RecommendationRemoteDataSource using Supabase
class RecommendationRemoteDataSourceImpl
    implements RecommendationRemoteDataSource {
  final SupabaseClient supabaseClient;

  RecommendationRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<RecommendationModel>> getProductRecommendations({
    required String currentProductId,
    RecommendationCriteriaEntity? criteria,
  }) async {
    try {
      // First, get the current product to extract criteria
      final currentProduct = await supabaseClient
          .from(DatabaseConstants.productsTable)
          .select()
          .eq('id', currentProductId)
          .single();

      final category =
          criteria?.category ?? currentProduct['category'] as String?;
      final sellerId =
          criteria?.sellerId ?? currentProduct['seller_id'] as String?;
      final universityIds =
          criteria?.universityIds ??
          (currentProduct['university_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final price =
          criteria?.price ?? (currentProduct['price'] as num?)?.toDouble();
      final priceRangePercent = criteria?.priceRangePercent ?? 0.2;
      final limit = criteria?.limit ?? 8;

      // Fetch potential recommendations
      var queryBuilder = supabaseClient
          .from(DatabaseConstants.productsTable)
          .select('*, users!inner(full_name, avatar_url)')
          .eq('is_active', true)
          .neq('id', currentProductId);

      // Apply filters
      if (category != null) {
        queryBuilder = queryBuilder.eq('category', category);
      }
      if (sellerId != null) {
        queryBuilder = queryBuilder.eq('seller_id', sellerId);
      }
      if (universityIds.isNotEmpty) {
        queryBuilder = queryBuilder.overlaps('university_ids', universityIds);
      }
      if (price != null) {
        final minPrice = price * (1 - priceRangePercent);
        final maxPrice = price * (1 + priceRangePercent);
        queryBuilder = queryBuilder
            .gte('price', minPrice)
            .lte('price', maxPrice);
      }

      final results = await queryBuilder.limit(limit * 2);

      // Calculate similarity scores
      final recommendations = <RecommendationModel>[];
      for (final item in results as List) {
        final itemId = item['id'] as String;
        final itemCategory = item['category'] as String?;
        final itemSellerId = item['seller_id'] as String?;
        final itemUniversityIds =
            (item['university_ids'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final itemPrice = (item['price'] as num?)?.toDouble() ?? 0.0;

        // Calculate similarity score
        double score = 0.0;
        final matchReasons = <String, dynamic>{};

        // Category match (0.4 weight)
        if (category != null && itemCategory == category) {
          score += 0.4;
          matchReasons['category'] = 0.4;
        }

        // Same seller (0.3 weight)
        if (sellerId != null && itemSellerId == sellerId) {
          score += 0.3;
          matchReasons['seller'] = 0.3;
        }

        // Same university (0.2 weight)
        if (universityIds.isNotEmpty &&
            itemUniversityIds.any((id) => universityIds.contains(id))) {
          score += 0.2;
          matchReasons['university'] = 0.2;
        }

        // Price within range (0.1 weight)
        if (price != null && itemPrice > 0) {
          final priceDiff = (itemPrice - price).abs() / price;
          if (priceDiff <= priceRangePercent) {
            score += 0.1;
            matchReasons['price'] = 0.1;
          }
        }

        if (score > 0) {
          recommendations.add(
            RecommendationModel(
              itemId: itemId,
              type: RecommendationType.product,
              similarityScore: score,
              matchReasons: matchReasons,
            ),
          );
        }
      }

      // Sort by similarity score and return top N
      recommendations.sort(
        (a, b) => b.similarityScore.compareTo(a.similarityScore),
      );
      return recommendations.take(limit).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get product recommendations: $e');
    }
  }

  @override
  Future<List<RecommendationModel>> getServiceRecommendations({
    required String currentServiceId,
    RecommendationCriteriaEntity? criteria,
  }) async {
    try {
      // First, get the current service to extract criteria
      final currentService = await supabaseClient
          .from(DatabaseConstants.servicesTable)
          .select()
          .eq('id', currentServiceId)
          .single();

      final category =
          criteria?.category ?? currentService['category'] as String?;
      final providerId =
          criteria?.sellerId ?? currentService['provider_id'] as String?;
      final universityIds =
          criteria?.universityIds ??
          (currentService['university_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final price =
          criteria?.price ?? (currentService['price'] as num?)?.toDouble();
      final priceRangePercent = criteria?.priceRangePercent ?? 0.2;
      final limit = criteria?.limit ?? 8;

      // Fetch potential recommendations
      var queryBuilder = supabaseClient
          .from(DatabaseConstants.servicesTable)
          .select('*, users!inner(full_name, avatar_url)')
          .eq('is_active', true)
          .neq('id', currentServiceId);

      // Apply filters
      if (category != null) {
        queryBuilder = queryBuilder.eq('category', category);
      }
      if (providerId != null) {
        queryBuilder = queryBuilder.eq('provider_id', providerId);
      }
      if (universityIds.isNotEmpty) {
        queryBuilder = queryBuilder.overlaps('university_ids', universityIds);
      }
      if (price != null) {
        final minPrice = price * (1 - priceRangePercent);
        final maxPrice = price * (1 + priceRangePercent);
        queryBuilder = queryBuilder
            .gte('price', minPrice)
            .lte('price', maxPrice);
      }

      final results = await queryBuilder.limit(limit * 2);

      // Calculate similarity scores
      final recommendations = <RecommendationModel>[];
      for (final item in results as List) {
        final itemId = item['id'] as String;
        final itemCategory = item['category'] as String?;
        final itemProviderId = item['provider_id'] as String?;
        final itemUniversityIds =
            (item['university_ids'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final itemPrice = (item['price'] as num?)?.toDouble() ?? 0.0;

        // Calculate similarity score
        double score = 0.0;
        final matchReasons = <String, dynamic>{};

        // Category match (0.4 weight)
        if (category != null && itemCategory == category) {
          score += 0.4;
          matchReasons['category'] = 0.4;
        }

        // Same provider (0.3 weight)
        if (providerId != null && itemProviderId == providerId) {
          score += 0.3;
          matchReasons['seller'] = 0.3;
        }

        // Same university (0.2 weight)
        if (universityIds.isNotEmpty &&
            itemUniversityIds.any((id) => universityIds.contains(id))) {
          score += 0.2;
          matchReasons['university'] = 0.2;
        }

        // Price within range (0.1 weight)
        if (price != null && itemPrice > 0) {
          final priceDiff = (itemPrice - price).abs() / price;
          if (priceDiff <= priceRangePercent) {
            score += 0.1;
            matchReasons['price'] = 0.1;
          }
        }

        if (score > 0) {
          recommendations.add(
            RecommendationModel(
              itemId: itemId,
              type: RecommendationType.service,
              similarityScore: score,
              matchReasons: matchReasons,
            ),
          );
        }
      }

      // Sort by similarity score and return top N
      recommendations.sort(
        (a, b) => b.similarityScore.compareTo(a.similarityScore),
      );
      return recommendations.take(limit).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get service recommendations: $e');
    }
  }

  @override
  Future<List<RecommendationModel>> getAccommodationRecommendations({
    required String currentAccommodationId,
    RecommendationCriteriaEntity? criteria,
  }) async {
    try {
      // First, get the current accommodation to extract criteria
      final currentAccommodation = await supabaseClient
          .from(DatabaseConstants.accommodationsTable)
          .select()
          .eq('id', currentAccommodationId)
          .single();

      final roomType =
          criteria?.category ?? currentAccommodation['room_type'] as String?;
      final ownerId =
          criteria?.sellerId ?? currentAccommodation['owner_id'] as String?;
      final universityIds =
          criteria?.universityIds ??
          (currentAccommodation['university_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final price =
          criteria?.price ??
          (currentAccommodation['price'] as num?)?.toDouble();
      final location =
          criteria?.location ?? currentAccommodation['location'] as String?;
      final priceRangePercent = criteria?.priceRangePercent ?? 0.2;
      final limit = criteria?.limit ?? 8;

      // Fetch potential recommendations
      var queryBuilder = supabaseClient
          .from(DatabaseConstants.accommodationsTable)
          .select('*, users!inner(full_name, avatar_url)')
          .eq('is_active', true)
          .neq('id', currentAccommodationId);

      // Apply filters
      if (roomType != null) {
        queryBuilder = queryBuilder.eq('room_type', roomType);
      }
      if (ownerId != null) {
        queryBuilder = queryBuilder.eq('owner_id', ownerId);
      }
      if (universityIds.isNotEmpty) {
        queryBuilder = queryBuilder.overlaps('university_ids', universityIds);
      }
      if (location != null) {
        queryBuilder = queryBuilder.ilike('location', '%$location%');
      }
      if (price != null) {
        final minPrice = price * (1 - priceRangePercent);
        final maxPrice = price * (1 + priceRangePercent);
        queryBuilder = queryBuilder
            .gte('price', minPrice)
            .lte('price', maxPrice);
      }

      final results = await queryBuilder.limit(limit * 2);

      // Calculate similarity scores
      final recommendations = <RecommendationModel>[];
      for (final item in results as List) {
        final itemId = item['id'] as String;
        final itemRoomType = item['room_type'] as String?;
        final itemOwnerId = item['owner_id'] as String?;
        final itemUniversityIds =
            (item['university_ids'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final itemPrice = (item['price'] as num?)?.toDouble() ?? 0.0;
        final itemLocation = item['location'] as String?;

        // Calculate similarity score
        double score = 0.0;
        final matchReasons = <String, dynamic>{};

        // Room type match (0.4 weight)
        if (roomType != null && itemRoomType == roomType) {
          score += 0.4;
          matchReasons['category'] = 0.4;
        }

        // Same owner (0.3 weight)
        if (ownerId != null && itemOwnerId == ownerId) {
          score += 0.3;
          matchReasons['seller'] = 0.3;
        }

        // Same university (0.2 weight)
        if (universityIds.isNotEmpty &&
            itemUniversityIds.any((id) => universityIds.contains(id))) {
          score += 0.2;
          matchReasons['university'] = 0.2;
        }

        // Price within range (0.1 weight)
        if (price != null && itemPrice > 0) {
          final priceDiff = (itemPrice - price).abs() / price;
          if (priceDiff <= priceRangePercent) {
            score += 0.1;
            matchReasons['price'] = 0.1;
          }
        }

        // Location match (bonus 0.05 weight)
        if (location != null && itemLocation != null) {
          if (itemLocation.toLowerCase().contains(location.toLowerCase()) ||
              location.toLowerCase().contains(itemLocation.toLowerCase())) {
            score += 0.05;
            matchReasons['location'] = 0.05;
          }
        }

        if (score > 0) {
          recommendations.add(
            RecommendationModel(
              itemId: itemId,
              type: RecommendationType.accommodation,
              similarityScore: score,
              matchReasons: matchReasons,
            ),
          );
        }
      }

      // Sort by similarity score and return top N
      recommendations.sort(
        (a, b) => b.similarityScore.compareTo(a.similarityScore),
      );
      return recommendations.take(limit).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get accommodation recommendations: $e');
    }
  }
}
