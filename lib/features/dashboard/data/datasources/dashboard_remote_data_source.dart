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

      return DashboardStatsModel(
        totalProducts: products.length,
        totalServices: (services as List).length,
        totalAccommodations: (accommodations as List).length,
        activeListings: activeProducts,
        totalViews: totalViews,
      );
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to get dashboard stats: $e');
    }
  }
}

