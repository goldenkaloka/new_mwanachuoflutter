import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/features/shared/university/data/models/university_model.dart';
import 'package:mwanachuo/features/shared/university/data/models/course_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract class defining university remote data source operations
abstract class UniversityRemoteDataSource {
  /// Get all universities from Supabase
  Future<List<UniversityModel>> getUniversities();

  /// Get university by ID from Supabase
  Future<UniversityModel> getUniversityById(String id);

  /// Search universities by name
  Future<List<UniversityModel>> searchUniversities(String query);

  /// Get courses for a university
  Future<List<CourseModel>> getUniversityCourses(String universityId);
}

/// Implementation of UniversityRemoteDataSource using Supabase
class UniversityRemoteDataSourceImpl implements UniversityRemoteDataSource {
  final SupabaseClient supabaseClient;

  UniversityRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<UniversityModel>> getUniversities() async {
    try {
      final response = await supabaseClient
          .from('universities')
          .select()
          .order('name');

      return (response as List)
          .map((json) => UniversityModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UniversityModel> getUniversityById(String id) async {
    try {
      final response = await supabaseClient
          .from('universities')
          .select()
          .eq('id', id)
          .single();

      return UniversityModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<UniversityModel>> searchUniversities(String query) async {
    try {
      final response = await supabaseClient
          .from('universities')
          .select()
          .or('name.ilike.%$query%,location.ilike.%$query%')
          .order('name');

      return (response as List)
          .map((json) => UniversityModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<CourseModel>> getUniversityCourses(String universityId) async {
    try {
      final response = await supabaseClient
          .from('courses')
          .select()
          .eq('university_id', universityId)
          .order('created_at');

      return (response as List)
          .map((json) => CourseModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
