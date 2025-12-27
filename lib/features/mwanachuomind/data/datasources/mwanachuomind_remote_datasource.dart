import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';
import '../../../../config/supabase_config.dart';
import '../models/course_model.dart';
import '../models/document_model.dart';
import '../models/chat_session_model.dart';

abstract class MwanachuomindRemoteDataSource {
  Future<List<CourseModel>> getCourses(String universityId);
  Future<void> createCourse(String code, String name, String universityId);
  Future<DocumentModel> uploadDocument(
    String courseId,
    String title,
    File file,
  );
  Stream<String> chat(
    String query,
    String courseId,
    List<Map<String, String>>? history, {
    String? documentId,
  });
  Future<String> createChatSession(String userId, String courseId);
  Future<List<ChatSessionModel>> getChatSessions(
    String userId,
    String courseId,
  );
  Future<void> renameChatSession(String sessionId, String title);
  Future<List<Map<String, dynamic>>> getSessionMessages(String sessionId);
  Future<void> saveMessage(String sessionId, String content, String sender);
  Future<CourseModel?> getEnrolledCourse(String userId);
  Future<void> setEnrolledCourse(String userId, String? courseId);
  Future<List<DocumentModel>> getCourseDocuments(String courseId);
}

class MwanachuomindRemoteDataSourceImpl
    implements MwanachuomindRemoteDataSource {
  final SupabaseClient supabaseClient;

  MwanachuomindRemoteDataSourceImpl({SupabaseClient? client})
    : supabaseClient = client ?? SupabaseConfig.client;

  @override
  Future<void> createCourse(
    String code,
    String name,
    String universityId,
  ) async {
    try {
      await supabaseClient.from('courses').insert({
        'code': code,
        'name': name,
        'university_id': universityId,
      });
    } catch (e) {
      throw Exception('Failed to create course: $e');
    }
  }

  @override
  Future<List<CourseModel>> getCourses(String universityId) async {
    final response = await supabaseClient
        .from('courses')
        .select()
        .eq('university_id', universityId)
        .order('created_at');

    return (response as List).map((e) => CourseModel.fromJson(e)).toList();
  }

  @override
  Future<DocumentModel> uploadDocument(
    String courseId,
    String title,
    File file,
  ) async {
    final fileExt = file.path.split('.').last.toLowerCase();

    // 1. Extract text content
    String extractedText = '';
    try {
      if (fileExt == 'pdf') {
        final bytes = await file.readAsBytes();
        final document = PdfDocument(inputBytes: bytes);
        final extractor = PdfTextExtractor(document);
        extractedText = extractor.extractText();
        document.dispose();
      } else if (fileExt == 'docx') {
        final bytes = await file.readAsBytes();
        extractedText = docxToText(bytes);
      } else if (fileExt == 'txt' || fileExt == 'md') {
        extractedText = await file.readAsString();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Warning: Text extraction failed: $e');
    }

    // 2. Upload file to storage
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = '$courseId/$fileName';

    await supabaseClient.storage
        .from('mwanachuomind_docs')
        .upload(
          filePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    // 3. Insert record with extracted text
    final docResponse = await supabaseClient
        .from('documents')
        .insert({
          'course_id': courseId,
          'title': title,
          'file_path': filePath,
          'extracted_text': extractedText,
          'metadata': {
            'original_name': file.path.split(Platform.pathSeparator).last,
            'size': await file.length(),
          },
        })
        .select()
        .single();

    final document = DocumentModel.fromJson(docResponse);

    return document;
  }

  @override
  Stream<String> chat(
    String query,
    String courseId,
    List<Map<String, String>>? history, {
    String? documentId,
  }) async* {
    try {
      final body = {
        'query': query,
        'course_id': courseId,
        'history': history ?? [],
      };
      if (documentId != null) {
        body['document_id'] = documentId;
      }

      final response = await supabaseClient.functions.invoke(
        'mwanachuomind-rag',
        body: body,
      );

      if (response.data is String) {
        yield response.data as String;
      } else {
        yield "Error: Unexpected response format";
      }
    } catch (e) {
      yield "Error: ${e.toString()}";
    }
  }

  @override
  Future<String> createChatSession(String userId, String courseId) async {
    try {
      final newSession = await supabaseClient
          .from('chat_sessions')
          .insert({
            'user_id': userId,
            'course_id': courseId,
            'title': 'New Chat',
          })
          .select('id')
          .single();
      return newSession['id'] as String;
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }

  @override
  Future<List<ChatSessionModel>> getChatSessions(
    String userId,
    String courseId,
  ) async {
    try {
      final response = await supabaseClient
          .from('chat_sessions')
          .select()
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((e) => ChatSessionModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch sessions: $e');
    }
  }

  @override
  Future<void> renameChatSession(String sessionId, String title) async {
    try {
      await supabaseClient
          .from('chat_sessions')
          .update({'title': title})
          .eq('id', sessionId);
    } catch (e) {
      throw Exception('Failed to rename session: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSessionMessages(
    String sessionId,
  ) async {
    final response = await supabaseClient
        .from('chat_messages')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> saveMessage(
    String sessionId,
    String content,
    String sender,
  ) async {
    await supabaseClient.from('chat_messages').insert({
      'session_id': sessionId,
      'content': content,
      'sender': sender,
    });

    await supabaseClient
        .from('chat_sessions')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', sessionId);
  }

  @override
  Future<CourseModel?> getEnrolledCourse(String userId) async {
    final userData = await supabaseClient
        .from('users')
        .select('enrolled_course_id')
        .eq('id', userId)
        .single();

    final courseId = userData['enrolled_course_id'] as String?;
    if (courseId == null) return null;

    final courseData = await supabaseClient
        .from('courses')
        .select()
        .eq('id', courseId)
        .single();

    return CourseModel.fromJson(courseData);
  }

  @override
  Future<void> setEnrolledCourse(String userId, String? courseId) async {
    await supabaseClient
        .from('users')
        .update({'enrolled_course_id': courseId})
        .eq('id', userId);
  }

  @override
  Future<List<DocumentModel>> getCourseDocuments(String courseId) async {
    final response = await supabaseClient
        .from('documents')
        .select()
        .eq('course_id', courseId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => DocumentModel.fromJson(e)).toList();
  }
}
