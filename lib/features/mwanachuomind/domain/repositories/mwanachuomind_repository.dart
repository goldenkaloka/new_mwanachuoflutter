import 'dart:io';
import '../entities/course.dart';
import '../entities/document.dart';

abstract class MwanachuomindRepository {
  Future<List<Course>> getUniversityCourses(String universityId);
  Future<void> createCourse({
    required String code,
    required String name,
    required String universityId,
  });
  Future<Document> uploadDocument({
    required String courseId,
    required String title,
    required File file,
  });
  Stream<String> chatStream({
    required String query,
    required String courseId,
    List<Map<String, String>>? history,
    String? documentId,
  });
  Future<String> getOrCreateSession(String userId, String courseId);
  Future<List<Map<String, dynamic>>> getSessionMessages(String sessionId);
  Future<void> saveMessage(String sessionId, String content, String sender);
  Future<Course?> getEnrolledCourse(String userId);
  Future<void> setEnrolledCourse(String userId, String? courseId);
  Future<List<Document>> getCourseDocuments(String courseId);
}
