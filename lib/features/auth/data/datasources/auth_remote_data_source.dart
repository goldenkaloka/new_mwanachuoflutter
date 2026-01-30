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
    String? registrationNumber,
    String? programName,
    String? userType,
    String? universityId,
    String? enrolledCourseId,
    int? yearOfStudy,
    int? currentSemester,
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
    String? businessName,
    String? tinNumber,
    String? businessCategory,
    String? registrationNumber,
    String? programName,
    String? userType,
    String? universityId,
    String? enrolledCourseId,
    int? yearOfStudy,
    int? currentSemester,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'name': name,
        'phone_number': phone,
        'user_type': userType ?? 'student',
      };

      if (businessName != null) data['business_name'] = businessName;
      if (tinNumber != null) data['tin_number'] = tinNumber;
      if (businessCategory != null) {
        data['business_category'] = businessCategory;
      }
      if (registrationNumber != null) {
        data['registration_number'] = registrationNumber;
      }
      if (programName != null) data['program_name'] = programName;
      if (universityId != null) data['primary_university_id'] = universityId;
      if (enrolledCourseId != null) {
        data['enrolled_course_id'] = enrolledCourseId;
      }
      if (yearOfStudy != null) data['year_of_study'] = yearOfStudy;
      if (currentSemester != null) data['current_semester'] = currentSemester;

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: data,
      );

      if (response.user == null) {
        throw const AuthenticationException('Sign up failed');
      }

      // Prepare database updates from metadata
      final dbUpdates = Map<String, dynamic>.from(data);
      // Map 'name' to 'full_name' for database column
      if (dbUpdates.containsKey('name')) {
        dbUpdates['full_name'] = dbUpdates.remove('name');
      }
      dbUpdates['updated_at'] = DateTime.now().toIso8601String();

      // Wait for the trigger to create user record (give it a moment)
      await Future.delayed(const Duration(milliseconds: 1500));

      // Check if user exists
      final userData = await supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      if (userData == null) {
        // Create user manually if trigger failed
        final insertData = Map<String, dynamic>.from(dbUpdates);
        insertData['id'] = response.user!.id;
        insertData['email'] = email;
        insertData['role'] = 'buyer'; // Default role

        await supabase.from('users').insert(insertData);
      } else {
        // Update existing user to ensure all metadata fields are synced
        // This is crucial because the trigger might missed some fields
        await supabase
            .from('users')
            .update(dbUpdates)
            .eq('id', response.user!.id);
      }

      // Fetch final user data
      final finalUserData = await supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
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
          .select()
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
          .single();

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
            .select()
            .eq('id', user.id)
            .single();

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
}
