import 'package:flutter/foundation.dart';
import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/profile/data/models/user_profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getUserProfile(String userId);
  Future<UserProfileModel> getMyProfile();
  Future<UserProfileModel> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? bio,
    String? location,
    String? avatarUrl,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final SupabaseClient supabaseClient;

  ProfileRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    Map<String, dynamic>? response;
    try {
      response = await supabaseClient
          .from(DatabaseConstants.usersTable)
          .select()
          .eq('id', userId)
          .single();

      // Get university name if user has a primary_university_id
      String? universityName;
      if (response['primary_university_id'] != null) {
        try {
          final universityId = response['primary_university_id'];
          final universityData = await supabaseClient
              .from('universities')
              .select('name')
              .eq('id', universityId)
              .maybeSingle();
          
          universityName = universityData?['name'] as String?;
        } catch (e) {
          // If university fetch fails, just continue without it
          debugPrint('Failed to fetch university: $e');
          universityName = null;
        }
      }

      // Get user's listing counts
      final productCount = await _getProductCount(userId);
      final serviceCount = await _getServiceCount(userId);
      final accommodationCount = await _getAccommodationCount(userId);

      return UserProfileModel.fromJson({
        ...response,
        'university_name': universityName,
        'product_count': productCount,
        'service_count': serviceCount,
        'accommodation_count': accommodationCount,
      });
    } on PostgrestException catch (e) {
      throw ServerException('Database error: ${e.message}');
    } catch (e, stackTrace) {
      debugPrint('Error in getUserProfile: $e');
      debugPrint('Response data: $response');
      debugPrint('Stack trace: $stackTrace');
      throw ServerException('Failed to get user profile: $e');
    }
  }

  @override
  Future<UserProfileModel> getMyProfile() async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      return await getUserProfile(currentUser.id);
    } on ServerException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ServerException('Database error: ${e.message}');
    } catch (e, stackTrace) {
      debugPrint('Error in getMyProfile: $e');
      debugPrint('Stack trace: $stackTrace');
      throw ServerException('Failed to get my profile: $e');
    }
  }

  @override
  Future<UserProfileModel> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? bio,
    String? location,
    String? avatarUrl,
  }) async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) throw ServerException('User not authenticated');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updateData['full_name'] = fullName;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (bio != null) updateData['bio'] = bio;
      if (location != null) updateData['location'] = location;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

      await supabaseClient
          .from(DatabaseConstants.usersTable)
          .update(updateData)
          .eq('id', currentUser.id);

      return await getMyProfile();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to update profile: $e');
    }
  }

  Future<int> _getProductCount(String userId) async {
    try {
      final response = await supabaseClient
          .from(DatabaseConstants.productsTable)
          .select()
          .eq('seller_id', userId)
          .eq('is_active', true);
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getServiceCount(String userId) async {
    try {
      final response = await supabaseClient
          .from(DatabaseConstants.servicesTable)
          .select()
          .eq('provider_id', userId)
          .eq('is_active', true);
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getAccommodationCount(String userId) async {
    try {
      final response = await supabaseClient
          .from(DatabaseConstants.accommodationsTable)
          .select()
          .eq('owner_id', userId)
          .eq('is_active', true);
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}

