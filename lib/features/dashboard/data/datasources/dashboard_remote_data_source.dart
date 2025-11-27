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

      // Get product stats
      final products = await supabaseClient
          .from(DatabaseConstants.productsTable)
          .select()
          .eq('seller_id', currentUser.id);

      final activeProducts = (products as List)
          .where((p) => p['is_active'] == true)
          .length;

      // Get service stats  
      final services = await supabaseClient
          .from(DatabaseConstants.servicesTable)
          .select()
          .eq('provider_id', currentUser.id);

      // Get accommodation stats
      final accommodations = await supabaseClient
          .from(DatabaseConstants.accommodationsTable)
          .select()
          .eq('owner_id', currentUser.id);

      // Calculate total views
      int totalViews = 0;
      for (var product in (products as List)) {
        totalViews += (product['view_count'] as int? ?? 0);
      }

      // Get last message time from conversations where user is participant
      DateTime? lastMessageTime;
      try {
        final conversations = await supabaseClient
            .from(DatabaseConstants.conversationsTable)
            .select('last_message_time')
            .or('user1_id.eq.${currentUser.id},user2_id.eq.${currentUser.id}')
            .not('last_message_time', 'is', null)
            .order('last_message_time', ascending: false)
            .limit(1);
        
        if ((conversations as List).isNotEmpty && conversations[0]['last_message_time'] != null) {
          lastMessageTime = DateTime.parse(conversations[0]['last_message_time']).toLocal();
        }
      } catch (e) {
        // Ignore errors, keep lastMessageTime as null
      }

      // Get last listing update time (most recent updated_at from products, services, accommodations)
      DateTime? lastListingUpdateTime;
      try {
        final allListings = <Map<String, dynamic>>[];
        
        // Get products
        final productsWithTime = await supabaseClient
            .from(DatabaseConstants.productsTable)
            .select('updated_at')
            .eq('seller_id', currentUser.id)
            .not('updated_at', 'is', null)
            .order('updated_at', ascending: false)
            .limit(1);
        allListings.addAll((productsWithTime as List).cast<Map<String, dynamic>>());
        
        // Get services
        final servicesWithTime = await supabaseClient
            .from(DatabaseConstants.servicesTable)
            .select('updated_at')
            .eq('provider_id', currentUser.id)
            .not('updated_at', 'is', null)
            .order('updated_at', ascending: false)
            .limit(1);
        allListings.addAll((servicesWithTime as List).cast<Map<String, dynamic>>());
        
        // Get accommodations
        final accommodationsWithTime = await supabaseClient
            .from(DatabaseConstants.accommodationsTable)
            .select('updated_at')
            .eq('owner_id', currentUser.id)
            .not('updated_at', 'is', null)
            .order('updated_at', ascending: false)
            .limit(1);
        allListings.addAll((accommodationsWithTime as List).cast<Map<String, dynamic>>());
        
        if (allListings.isNotEmpty) {
          allListings.sort((a, b) {
            final aTime = a['updated_at'] != null ? DateTime.parse(a['updated_at']) : DateTime(1970);
            final bTime = b['updated_at'] != null ? DateTime.parse(b['updated_at']) : DateTime(1970);
            return bTime.compareTo(aTime);
          });
          if (allListings[0]['updated_at'] != null) {
            lastListingUpdateTime = DateTime.parse(allListings[0]['updated_at']).toLocal();
          }
        }
      } catch (e) {
        // Ignore errors, keep lastListingUpdateTime as null
      }

      // Get last review time (most recent review for seller's items)
      DateTime? lastReviewTime;
      try {
        // Get product reviews
        final productIds = (products as List).map((p) => p['id'] as String).toList();
        final serviceIds = (services as List).map((s) => s['id'] as String).toList();
        final accommodationIds = (accommodations as List).map((a) => a['id'] as String).toList();
        
        final allReviews = <Map<String, dynamic>>[];
        
        if (productIds.isNotEmpty) {
          final productReviews = await supabaseClient
              .from('product_reviews')
              .select('created_at')
              .inFilter('item_id', productIds)
              .order('created_at', ascending: false)
              .limit(1);
          allReviews.addAll((productReviews as List).cast<Map<String, dynamic>>());
        }
        
        if (serviceIds.isNotEmpty) {
          final serviceReviews = await supabaseClient
              .from('service_reviews')
              .select('created_at')
              .inFilter('item_id', serviceIds)
              .order('created_at', ascending: false)
              .limit(1);
          allReviews.addAll((serviceReviews as List).cast<Map<String, dynamic>>());
        }
        
        if (accommodationIds.isNotEmpty) {
          final accommodationReviews = await supabaseClient
              .from('accommodation_reviews')
              .select('created_at')
              .inFilter('item_id', accommodationIds)
              .order('created_at', ascending: false)
              .limit(1);
          allReviews.addAll((accommodationReviews as List).cast<Map<String, dynamic>>());
        }
        
        if (allReviews.isNotEmpty) {
          allReviews.sort((a, b) {
            final aTime = a['created_at'] != null ? DateTime.parse(a['created_at']) : DateTime(1970);
            final bTime = b['created_at'] != null ? DateTime.parse(b['created_at']) : DateTime(1970);
            return bTime.compareTo(aTime);
          });
          if (allReviews[0]['created_at'] != null) {
            lastReviewTime = DateTime.parse(allReviews[0]['created_at']).toLocal();
          }
        }
      } catch (e) {
        // Ignore errors, keep lastReviewTime as null
      }

      return DashboardStatsModel(
        totalProducts: products.length,
        totalServices: (services as List).length,
        totalAccommodations: (accommodations as List).length,
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

