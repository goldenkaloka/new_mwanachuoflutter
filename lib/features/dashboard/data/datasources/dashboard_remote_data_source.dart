import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/dashboard/data/models/dashboard_stats_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardStatsModel> getDashboardStats();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final SupabaseClient supabaseClient;

  DashboardRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<DashboardStatsModel> getDashboardStats() async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      // Parallelize the main data fetching operations
      final results = await Future.wait([
        // Query 1: Get products with only required fields
        supabaseClient
            .from(DatabaseConstants.productsTable)
            .select('id, is_active, view_count, updated_at')
            .eq('seller_id', currentUser.id),

        // Query 2: Get services with only required fields
        supabaseClient
            .from(DatabaseConstants.servicesTable)
            .select('id, updated_at')
            .eq('provider_id', currentUser.id),

        // Query 3: Get accommodations with only required fields
        supabaseClient
            .from(DatabaseConstants.accommodationsTable)
            .select('id, updated_at')
            .eq('owner_id', currentUser.id),

        // Query 4: Get last conversation time
        supabaseClient
            .from(DatabaseConstants.conversationsTable)
            .select('last_message_time')
            .or('user1_id.eq.${currentUser.id},user2_id.eq.${currentUser.id}')
            .not('last_message_time', 'is', null)
            .order('last_message_time', ascending: false)
            .limit(1),
      ]);

      final products = results[0] as List;
      final services = results[1] as List;
      final accommodations = results[2] as List;
      final conversations = results[3] as List;

      // Calculate stats from products
      final activeProducts = products
          .where((p) => p['is_active'] == true)
          .length;
      int totalViews = 0;
      for (var product in products) {
        totalViews += (product['view_count'] as int? ?? 0);
      }

      // Get last message time
      DateTime? lastMessageTime;
      if (conversations.isNotEmpty &&
          conversations[0]['last_message_time'] != null) {
        lastMessageTime = DateTime.parse(
          conversations[0]['last_message_time'],
        ).toLocal();
      }

      // Get last listing update time - find most recent from all three collections
      DateTime? lastListingUpdateTime;
      final allUpdatedAts = <DateTime>[];

      for (var product in products) {
        if (product['updated_at'] != null) {
          allUpdatedAts.add(DateTime.parse(product['updated_at']));
        }
      }
      for (var service in services) {
        if (service['updated_at'] != null) {
          allUpdatedAts.add(DateTime.parse(service['updated_at']));
        }
      }
      for (var accommodation in accommodations) {
        if (accommodation['updated_at'] != null) {
          allUpdatedAts.add(DateTime.parse(accommodation['updated_at']));
        }
      }

      if (allUpdatedAts.isNotEmpty) {
        allUpdatedAts.sort((a, b) => b.compareTo(a));
        lastListingUpdateTime = allUpdatedAts.first.toLocal();
      }

      // Get last review time - parallelize review queries
      DateTime? lastReviewTime;
      try {
        final productIds = products.map((p) => p['id'] as String).toList();
        final serviceIds = services.map((s) => s['id'] as String).toList();
        final accommodationIds = accommodations
            .map((a) => a['id'] as String)
            .toList();

        final reviewQueries = <Future<List<Map<String, dynamic>>>>[];

        if (productIds.isNotEmpty) {
          reviewQueries.add(
            supabaseClient
                .from('product_reviews')
                .select('created_at')
                .inFilter('item_id', productIds)
                .order('created_at', ascending: false)
                .limit(1)
                .then(
                  (result) => (result as List).cast<Map<String, dynamic>>(),
                ),
          );
        }

        if (serviceIds.isNotEmpty) {
          reviewQueries.add(
            supabaseClient
                .from('service_reviews')
                .select('created_at')
                .inFilter('item_id', serviceIds)
                .order('created_at', ascending: false)
                .limit(1)
                .then(
                  (result) => (result as List).cast<Map<String, dynamic>>(),
                ),
          );
        }

        if (accommodationIds.isNotEmpty) {
          reviewQueries.add(
            supabaseClient
                .from('accommodation_reviews')
                .select('created_at')
                .inFilter('item_id', accommodationIds)
                .order('created_at', ascending: false)
                .limit(1)
                .then(
                  (result) => (result as List).cast<Map<String, dynamic>>(),
                ),
          );
        }

        if (reviewQueries.isNotEmpty) {
          final reviewResults = await Future.wait(reviewQueries);
          final allReviews = <Map<String, dynamic>>[];
          for (var result in reviewResults) {
            allReviews.addAll(result);
          }

          if (allReviews.isNotEmpty) {
            allReviews.sort((a, b) {
              final aTime = a['created_at'] != null
                  ? DateTime.parse(a['created_at'])
                  : DateTime(1970);
              final bTime = b['created_at'] != null
                  ? DateTime.parse(b['created_at'])
                  : DateTime(1970);
              return bTime.compareTo(aTime);
            });
            if (allReviews[0]['created_at'] != null) {
              lastReviewTime = DateTime.parse(
                allReviews[0]['created_at'],
              ).toLocal();
            }
          }
        }
      } catch (e) {
        // Ignore errors, keep lastReviewTime as null
      }

      return DashboardStatsModel(
        totalProducts: products.length,
        totalServices: services.length,
        totalAccommodations: accommodations.length,
        activeListings: activeProducts,
        totalViews: totalViews,
        lastMessageTime: lastMessageTime,
        lastListingUpdateTime: lastListingUpdateTime,
        lastReviewTime: lastReviewTime,
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get dashboard stats: $e');
    }
  }
}
