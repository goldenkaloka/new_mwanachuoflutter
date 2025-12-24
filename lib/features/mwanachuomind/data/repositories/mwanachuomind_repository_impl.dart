import 'dart:io';
import '../../domain/entities/course.dart';
import '../../domain/entities/document.dart';
import '../../domain/repositories/mwanachuomind_repository.dart';
import '../datasources/mwanachuomind_remote_datasource.dart';

class MwanachuomindRepositoryImpl implements MwanachuomindRepository {
  final MwanachuomindRemoteDataSource remoteDataSource;

  MwanachuomindRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> createCourse({
    required String code,
    required String name,
    required String universityId,
  }) async {
    return await remoteDataSource.createCourse(code, name, universityId);
  }

  @override
  Future<List<Course>> getUniversityCourses(String universityId) async {
    return await remoteDataSource.getCourses(universityId);
  }

  @override
  Future<Document> uploadDocument({
    required String courseId,
    required String title,
    required File file,
  }) async {
    return await remoteDataSource.uploadDocument(courseId, title, file);
  }

  @override
  Stream<String> chatStream({
    required String query,
    required String courseId,
    List<Map<String, String>>? history,
    String? documentId,
  }) {
    return remoteDataSource.chat(
      query,
      courseId,
      history,
      documentId: documentId,
    );
  }

  @override
  Future<String> getOrCreateSession(String userId, String courseId) {
    return remoteDataSource.getOrCreateSession(userId, courseId);
  }

  @override
  Future<List<Map<String, dynamic>>> getSessionMessages(String sessionId) {
    return remoteDataSource.getSessionMessages(sessionId);
  }

  @override
  Future<void> saveMessage(String sessionId, String content, String sender) {
    return remoteDataSource.saveMessage(sessionId, content, sender);
  }

  @override
  Future<Course?> getEnrolledCourse(String userId) {
    return remoteDataSource.getEnrolledCourse(userId);
  }

  @override
  Future<void> setEnrolledCourse(String userId, String? courseId) {
    return remoteDataSource.setEnrolledCourse(userId, courseId);
  }

  @override
  Future<List<Document>> getCourseDocuments(String courseId) {
    return remoteDataSource.getCourseDocuments(courseId);
  }
}
