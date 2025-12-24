import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/auth/data/models/seller_request_model.dart';
import 'package:mwanachuo/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  });
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<void> requestSellerAccess({
    required String userId,
    required String reason,
  });
  Future<void> approveSellerRequest({
    required String requestId,
    required String adminId,
    String? notes,
  });
  Future<void> rejectSellerRequest({
    required String requestId,
    required String adminId,
    String? notes,
  });
  Future<UserModel> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? profilePicture,
  });
  Future<void> completeRegistration({
    required String userId,
    required String primaryUniversityId,
    required List<String> subsidiaryUniversityIds,
  });
  Future<bool> checkRegistrationCompletion();
  Future<String?> getSellerRequestStatus();
  Future<List<SellerRequestModel>> getSellerRequests({String? status});
  Future<SellerRequestModel> getSellerRequestById(String requestId);
  Stream<UserModel?> watchAuthState();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabase;

  AuthRemoteDataSourceImpl(this.supabase);

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const AuthenticationException('Sign in failed');
      }

      // Fetch user data from users table
      final userData = await supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      return UserModel.fromJson(userData);
    } on AuthException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'phone_number': phone},
      );

      if (response.user == null) {
        throw const AuthenticationException('Sign up failed');
      }

      // Wait for the trigger to create user record (give it a moment)
      await Future.delayed(const Duration(milliseconds: 1500));

      // Fetch user data from users table
      final userData = await supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      // If user record not created by trigger yet, create it manually
      if (userData == null) {
        await supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'full_name': name,
          'phone_number': phone,
          'role': 'buyer',
        });

        final newUserData = await supabase
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();

        return UserModel.fromJson(newUserData);
      }

      // If user data exists but phone wasn't set by trigger from metadata
      if (userData['phone_number'] == null ||
          (userData['phone_number'] as String).isEmpty) {
        await supabase
            .from('users')
            .update({'phone_number': phone})
            .eq('id', response.user!.id);

        final updatedData = await supabase
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();
        return UserModel.fromJson(updatedData);
      }

      return UserModel.fromJson(userData);
    } on AuthException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        return null;
      }

      final userData = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return UserModel.fromJson(userData);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> requestSellerAccess({
    required String userId,
    required String reason,
  }) async {
    try {
      await supabase.from('seller_requests').insert({
        'user_id': userId,
        'reason': reason,
        'status': 'pending',
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> approveSellerRequest({
    required String requestId,
    required String adminId,
    String? notes,
  }) async {
    try {
      await supabase.rpc(
        'approve_seller_request',
        params: {'request_id': requestId, 'admin_id': adminId, 'notes': notes},
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> rejectSellerRequest({
    required String requestId,
    required String adminId,
    String? notes,
  }) async {
    try {
      await supabase
          .from('seller_requests')
          .update({
            'status': 'rejected',
            'reviewed_by': adminId,
            'review_notes': notes,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? profilePicture,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (profilePicture != null) updates['profile_picture'] = profilePicture;
      updates['updated_at'] = DateTime.now().toIso8601String();

      final userData = await supabase
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return UserModel.fromJson(userData);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> completeRegistration({
    required String userId,
    required String primaryUniversityId,
    required List<String> subsidiaryUniversityIds,
  }) async {
    try {
      await supabase.rpc(
        'complete_registration_with_universities',
        params: {
          'p_user_id': userId,
          'p_primary_university_id': primaryUniversityId,
          'p_subsidiary_university_ids': subsidiaryUniversityIds,
        },
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> checkRegistrationCompletion() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        return false;
      }

      final userData = await supabase
          .from('users')
          .select('registration_completed')
          .eq('id', userId)
          .single();

      return userData['registration_completed'] as bool? ?? false;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String?> getSellerRequestStatus() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        return null;
      }

      final response = await supabase
          .from('seller_requests')
          .select('status')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return response['status'] as String?;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<SellerRequestModel>> getSellerRequests({String? status}) async {
    try {
      var query = supabase.from('seller_requests').select('''
            *,
            requester:users!seller_requests_user_id_fkey(id, full_name, email, avatar_url),
            reviewer:users!seller_requests_reviewed_by_fkey(id, full_name, email)
          ''');

      if (status != null) {
        query = query.eq('status', status);
      }

      final data = await query.order('created_at', ascending: false);

      return (data as List)
          .map(
            (json) => SellerRequestModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw ServerException('Failed to get seller requests: $e');
    }
  }

  @override
  Future<SellerRequestModel> getSellerRequestById(String requestId) async {
    try {
      final data = await supabase
          .from('seller_requests')
          .select('''
            *,
            requester:users!seller_requests_user_id_fkey(id, full_name, email, avatar_url),
            reviewer:users!seller_requests_reviewed_by_fkey(id, full_name, email)
          ''')
          .eq('id', requestId)
          .single();

      return SellerRequestModel.fromJson(data);
    } catch (e) {
      throw ServerException('Failed to get seller request: $e');
    }
  }

  @override
  Stream<UserModel?> watchAuthState() {
    return supabase.auth.onAuthStateChange.asyncMap((data) async {
      final user = data.session?.user;

      if (user == null) {
        return null;
      }

      try {
        final userData = await supabase
            .from('users')
            .select()
            .eq('id', user.id)
            .single();

        return UserModel.fromJson(userData);
      } catch (e) {
        return null;
      }
    });
  }
}
