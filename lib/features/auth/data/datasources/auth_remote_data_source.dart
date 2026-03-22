import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';

import 'package:mwanachuo/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    String? businessName,
    String? tinNumber,
    String? businessCategory,
    String? programName,
    String? userType,
    String? universityId,
    String? enrolledCourseId,
    int? yearOfStudy,
    int? currentSemester,
    String? vehicleType,
    String? vehiclePlate,
    String? studentIdNumber,
  });
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();

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

  Stream<UserModel?> watchAuthState();
  Future<void> resetPassword(String email);
  Future<void> consumeFreeListing(String userId);
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

      // Fetch user data from users table with specialized extensions
      final userData = await supabase
          .from('users')
          .select('*, students(*), sellers(*), riders(*)')
          .eq('id', response.user!.id)
          .maybeSingle();

      if (userData == null) {
        // Profile might be being created by trigger, wait briefly and retry once
        await Future.delayed(const Duration(milliseconds: 500));
        final retriedData = await supabase
            .from('users')
            .select('*, students(*), sellers(*), riders(*)')
            .eq('id', response.user!.id)
            .maybeSingle();
        
        if (retriedData != null) {
          return UserModel.fromJson(retriedData);
        }

        // Fallback: Create user manually if trigger failed even after retry
        final metadata = response.user!.userMetadata ?? {};
        final insertData = {
          'id': response.user!.id,
          'email': response.user!.email,
          'full_name': metadata['full_name'] ?? metadata['name'] ?? 'User',
          'phone_number': metadata['phone_number'] ?? metadata['phone'],
          'user_type': metadata['user_type'] ?? 'student',
          'role': 'buyer',
          'updated_at': DateTime.now().toIso8601String(),
        };

        final createdData = await supabase
            .from('users')
            .insert(insertData)
            .select('*, students(*), sellers(*), riders(*)')
            .single();
        return UserModel.fromJson(createdData);
      }

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
    String? businessName,
    String? tinNumber,
    String? businessCategory,
    String? programName,
    String? userType,
    String? universityId,
    String? enrolledCourseId,
    int? yearOfStudy,
    int? currentSemester,
    String? vehicleType,
    String? vehiclePlate,
    String? studentIdNumber,
  }) async {
    try {
      final Map<String, dynamic> metadata = {
        'name': name,
        'phone_number': phone,
        'user_type': userType ?? 'student',
      };

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );

      if (response.user == null) {
        throw const AuthenticationException('Sign up failed');
      }

      final userId = response.user!.id;

      // Prepare database updates for core profile
      final coreUpdates = {
        'full_name': name,
        'phone_number': phone,
        'user_type': userType ?? 'student',
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Wait a tiny bit for the trigger to at least create the base user record
      await Future.delayed(const Duration(milliseconds: 200));

      // 1. Update Core Profile (ensures sync if trigger was slow or metadata missed)
      await supabase.from('users').upsert({
        'id': userId,
        'email': email,
        ...coreUpdates,
      });

      // 2. Handle specialized table inserts based on user type
      if (userType == 'student') {
        final studentData = {
          'user_id': userId,
          'program_name': programName,
          'year_of_study': yearOfStudy,
          'current_semester': currentSemester,
          'student_id_number': studentIdNumber,
        };
        await supabase.from('students').upsert(studentData);
      } else if (userType == 'business' || businessName != null) {
        final sellerData = {
          'user_id': userId,
          'business_name': businessName,
          'tin_number': tinNumber,
          'business_category': businessCategory,
        };
        await supabase.from('sellers').upsert(sellerData);
      } else if (userType == 'rider') {
        final riderData = {
          'user_id': userId,
          'vehicle_type': vehicleType ?? 'Foot',
          'vehicle_plate': vehiclePlate,
          'student_id_number': studentIdNumber,
          'is_approved': false,
        };
        await supabase.from('riders').upsert(riderData);
      }

      // 3. Fetch final user data with all extensions
      final finalUserData = await supabase
          .from('users')
          .select('*, students(*), sellers(*), riders(*)')
          .eq('id', userId)
          .single();

      return UserModel.fromJson(finalUserData);
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
          .select('*, students(*), sellers(*), riders(*)')
          .eq('id', user.id)
          .maybeSingle();

      if (userData == null) {
        return null;
      }

      return UserModel.fromJson(userData);
    } catch (e) {
      // If the error indicates invalid authentication (e.g. deleted user, expired token),
      // we must return null so the repository clears the cache.
      final msg = e.toString().toLowerCase();
      if (msg.contains('jwt') ||
          msg.contains('json web token') ||
          msg.contains('unauthorized') ||
          msg.contains('invalid refresh token')) {
        return null;
      }

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
        throw const AuthenticationException('User not authenticated');
      }

      final userData = await supabase
          .from('users')
          .select('registration_completed')
          .eq('id', userId)
          .maybeSingle();

      if (userData == null) return false;

      return userData['registration_completed'] as bool? ?? false;
    } catch (e) {
      throw ServerException(e.toString());
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
            .select('*, students(*), sellers(*), riders(*)')
            .eq('id', user.id)
            .maybeSingle();

        if (userData == null) return null;

        return UserModel.fromJson(userData);
      } catch (e) {
        return null;
      }
    });
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw AuthenticationException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> consumeFreeListing(String userId) async {
    try {
      await supabase.rpc(
        'decrement_free_listings',
        params: {'p_user_id': userId},
      );
    } catch (e) {
      // Fallback to manual update if RPC doesn't exist (e.g. migration failed)
      try {
        final userData = await supabase
            .from('users')
            .select('free_listings_count')
            .eq('id', userId)
            .single();

        final currentCount = userData['free_listings_count'] as int? ?? 0;
        if (currentCount > 0) {
          await supabase
              .from('users')
              .update({'free_listings_count': currentCount - 1})
              .eq('id', userId);
        }
      } catch (innerE) {
        throw ServerException(innerE.toString());
      }
    }
  }
}
