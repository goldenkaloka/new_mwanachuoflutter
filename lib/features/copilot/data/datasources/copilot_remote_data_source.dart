import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mwanachuo/features/copilot/data/models/note_model.dart';
import 'package:mwanachuo/features/copilot/data/models/concept_model.dart';
import 'package:mwanachuo/features/copilot/data/models/flashcard_model.dart';
import 'package:mwanachuo/features/copilot/data/models/tag_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:async';
import 'package:mime/mime.dart'; // Ensure you have this package or use lookupMimeType logic

abstract class CopilotRemoteDataSource {
  /// Upload file to Supabase Storage and create note record
  Future<Map<String, dynamic>> uploadAndAnalyze({
    required File file,
    required String noteId,
    required String courseId,
    String? title,
  });

  /// Get notes for a course from Supabase
  Future<List<NoteModel>> getCourseNotes({
    required String courseId,
    String? filterBy,
  });

  /// Get note by ID
  Future<NoteModel> getNoteById(String noteId);

  /// Get concepts for a note
  Future<List<ConceptModel>> getNoteConcepts(String noteId);

  /// Get flashcards for a note
  Future<List<FlashcardModel>> getNoteFlashcards(String noteId);

  /// Get tags for a note
  Future<List<TagModel>> getNoteTags(String noteId);

  /// Query with RAG (streaming)
  Stream<String> queryWithRag({
    required String question,
    required String noteId,
    required String courseId,
    List<Map<String, dynamic>>? history,
  });

  /// Semantic search
  Future<List<NoteModel>> semanticSearch({
    required String query,
    required String courseId,
    int limit = 10,
  });
}

class CopilotRemoteDataSourceImpl implements CopilotRemoteDataSource {
  final SupabaseClient supabase;
  final http.Client httpClient;

  CopilotRemoteDataSourceImpl({
    required this.supabase,
    required this.httpClient,
  });

  @override
  Future<Map<String, dynamic>> uploadAndAnalyze({
    required File file,
    required String noteId,
    required String courseId,
    String? title,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // 1. Upload to Supabase Storage
      final fileExt = file.path.split('.').last;
      final filePath = '$userId/$courseId/$noteId.$fileExt';

      await supabase.storage
          .from('course_notes')
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final publicUrl = supabase.storage
          .from('course_notes')
          .getPublicUrl(filePath);

      // 2. Insert into course_notes table
      // Note: We use the existing noteId passed from the repository
      final noteData = {
        'id': noteId,
        'title': title ?? file.path.split('/').last,
        'course_id': courseId,
        'uploaded_by': userId,
        'file_url': publicUrl,
        'file_size': await file.length(),
        'file_type': lookupMimeType(file.path) ?? 'application/pdf',
        'is_official': false,
        'year_relevance': 1, // Default, should be passed or updated later
        'study_readiness_score': 0, // Pending analysis
      };

      await supabase.from('course_notes').insert(noteData);

      // 3. Return status (matching previous API structure partially for compatibility)
      return {
        'status': 'queued',
        'note_id': noteId,
        'message': 'Upload successful. AI processing started.',
      };
    } catch (e) {
      throw Exception('Failed to upload note: $e');
    }
  }

  @override
  Future<List<NoteModel>> getCourseNotes({
    required String courseId,
    String? filterBy,
  }) async {
    try {
      PostgrestFilterBuilder query = supabase
          .from('course_notes')
          .select()
          .eq('course_id', courseId);

      // Apply filter
      if (filterBy == 'official') {
        query = query.eq('is_official', true);
      } else if (filterBy == 'my_notes') {
        final userId = supabase.auth.currentUser?.id;
        if (userId != null) {
          query = query.eq('uploaded_by', userId);
        }
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((json) => NoteModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get course notes: $e');
    }
  }

  @override
  Future<NoteModel> getNoteById(String noteId) async {
    try {
      final response = await supabase
          .from('course_notes')
          .select()
          .eq('id', noteId)
          .single();

      return NoteModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get note: $e');
    }
  }

  @override
  Future<List<ConceptModel>> getNoteConcepts(String noteId) async {
    try {
      final response = await supabase
          .from('note_concepts')
          .select()
          .eq('note_id', noteId)
          .order('page_number');

      return (response as List)
          .map((json) => ConceptModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return empty if analysis not done yet
      return [];
    }
  }

  @override
  Future<List<FlashcardModel>> getNoteFlashcards(String noteId) async {
    try {
      final response = await supabase
          .from('note_flashcards')
          .select()
          .eq('note_id', noteId);

      return (response as List)
          .map((json) => FlashcardModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<TagModel>> getNoteTags(String noteId) async {
    try {
      final response = await supabase
          .from('note_tags')
          .select()
          .eq('note_id', noteId);

      return (response as List)
          .map((json) => TagModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Stream<String> queryWithRag({
    required String question,
    required String noteId,
    required String courseId,
    List<Map<String, dynamic>>? history,
  }) async* {
    try {
      final response = await supabase.functions.invoke(
        'chat-with-copilot',
        body: {
          'message': question,
          'note_id': noteId,
          'history': history ?? [],
        },
      );

      final data = response.data;
      if (data != null && data['answer'] != null) {
        yield data['answer'];
      } else if (data != null && data['error'] != null) {
        yield "Error: ${data['error']}";
      } else {
        yield "Error: No response from AI.";
      }
    } catch (e) {
      yield "Error querying AI: $e";
    }
  }

  @override
  Future<List<NoteModel>> semanticSearch({
    required String query,
    required String courseId,
    int limit = 10,
  }) async {
    // TODO: Implement semantic search edge function if needed.
    // For now, this is a placeholder as the main focus is RAG Chat.
    return [];
  }
}
