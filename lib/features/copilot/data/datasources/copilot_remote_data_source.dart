import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mwanachuo/config/supabase_config.dart';
import 'package:mwanachuo/features/copilot/data/models/note_model.dart';
import 'package:mwanachuo/features/copilot/data/models/concept_model.dart';
import 'package:mwanachuo/features/copilot/data/models/flashcard_model.dart';
import 'package:mwanachuo/features/copilot/data/models/tag_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:mime/mime.dart'; // Ensure you have this package or use lookupMimeType logic

import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

abstract class CopilotRemoteDataSource {
  /// Upload file to Supabase Storage and create note record
  Future<Map<String, dynamic>> uploadAndAnalyze({
    required File file,
    required String noteId,
    required String courseId,
    String? title,
    int? year,
    int? semester,
  });

  /// Get notes for a course from Supabase
  Future<List<NoteModel>> getCourseNotes({
    required String courseId,
    String? filterBy,
    int? year,
    int? semester,
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
    required String courseId,
    String? noteId,
    List<Map<String, dynamic>>? history,
  });

  /// Semantic search
  Future<List<NoteModel>> semanticSearch({
    required String query,
    required String courseId,
    int limit = 10,
  });

  /// Increment view count
  Future<void> incrementViewCount(String noteId);

  /// Increment download count
  Future<void> incrementDownloadCount(String noteId);
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
    int? year,
    int? semester,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // 1. Upload to Supabase Storage
      final String fileName = p.basename(file.path);
      // Ensure specific extension handling if needed, but basename handles filename.ext correctly
      // However, typical file upload paths often need the extension separately if not just uploading the blob with a name.
      // But here we construct "noteId.ext".
      final fileExt = p.extension(file.path).replaceAll('.', '');
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
        'title': title ?? fileName,
        'course_id': courseId,
        'uploaded_by': userId,
        'file_url': publicUrl,
        'file_size': await file.length(),
        'file_type': lookupMimeType(file.path) ?? 'application/pdf',
        'is_official': false,
        'year_relevance': year ?? 1,
        'semester': semester ?? 1,
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
    int? year,
    int? semester,
  }) async {
    try {
      PostgrestFilterBuilder query = supabase
          .from('course_notes')
          .select('*, users:uploaded_by(full_name)')
          .eq('course_id', courseId);

      // Apply year/semester filter if provided
      if (year != null) {
        query = query.eq('year_relevance', year);
      }
      if (semester != null) {
        query = query.eq('semester', semester);
      }

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
      return (response as List).map((json) {
        final Map<String, dynamic> noteJson = Map<String, dynamic>.from(json);
        final users = noteJson['users'];
        if (users != null) {
          noteJson['uploader_name'] = users['full_name'];
        }
        return NoteModel.fromJson(noteJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get course notes: $e');
    }
  }

  @override
  Future<NoteModel> getNoteById(String noteId) async {
    try {
      final response = await supabase
          .from('course_notes')
          .select('*, users:uploaded_by(full_name)')
          .eq('id', noteId)
          .single();

      final Map<String, dynamic> noteJson = Map<String, dynamic>.from(response);
      final users = noteJson['users'];
      if (users != null) {
        noteJson['uploader_name'] = users['full_name'];
      }
      return NoteModel.fromJson(noteJson);
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
    required String courseId,
    String? noteId,
    List<Map<String, dynamic>>? history,
  }) async* {
    final url = Uri.parse(
      '${SupabaseConfig.supabaseUrl}/functions/v1/chat-with-copilot',
    );
    final client = http.Client();

    try {
      final streamedRequest = http.Request('POST', url)
        ..headers.addAll({
          'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
          'apikey': SupabaseConfig.supabaseAnonKey,
        })
        ..body = jsonEncode({
          'message': question,
          'note_id': noteId,
          'course_id': courseId,
          'history': history ?? [],
        });

      final response = await client.send(streamedRequest);

      if (response.statusCode != 200) {
        yield "Error: AI Service returned ${response.statusCode}";
        return;
      }

      await for (final chunk
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (chunk.startsWith('data: ')) {
          final dataStr = chunk.substring(6).trim();
          if (dataStr.isEmpty) continue;
          if (dataStr == '[DONE]') break;
          try {
            final data = jsonDecode(dataStr);
            if (data['answer'] != null) {
              yield data['answer'];
            } else if (data['error'] != null) {
              yield "Error: ${data['error']}";
            }
          } catch (e) {
            // Ignore malformed JSON chunks if any
          }
        }
      }
    } catch (e) {
      yield "Error querying AI: $e";
    } finally {
      client.close();
    }
  }

  @override
  Future<List<NoteModel>> semanticSearch({
    required String query,
    required String courseId,
    int? limit,
  }) async {
    try {
      // For performance, we first generate the embedding using a dedicated lightweight function
      // or directly via calling a service. But since we want to move logic to RPC:
      // We will invoke a helper that just returns the embedding and then calls RPC,
      // or we can use a "search-rpc" function that is optimized.

      // Let's assume for now we still need the embedding.
      // Actually, many "semantic-search" edge functions are slow because they do too much.
      // We'll keep using the function but ensure it's pointing to the optimized SQL.

      final response = await supabase.functions.invoke(
        'chat-with-copilot',
        body: {
          'query': query,
          'course_id': courseId,
          'limit': limit ?? 5,
          'mode': 'search',
        },
      );

      if (response.status != 200) {
        throw Exception('Search failed with status: ${response.status}');
      }

      final List<dynamic> data = response.data;
      return data.map((json) {
        // Handle potentially different formats from unified search
        return NoteModel(
          id: json['id'],
          title: json['title'],
          description: json['description'] ?? json['extracted_text'],
          courseId: courseId,
          uploadedBy: json['uploaded_by'] ?? '',
          fileUrl: json['file_url'] ?? '',
          fileSize: json['file_size'] ?? 0,
          fileType: json['file_type'] ?? 'pdf',
          studyReadinessScore: (json['study_readiness_score'] ?? 100.0)
              .toDouble(),
          downloadCount: json['download_count'] ?? 0,
          viewCount: json['view_count'] ?? 0,
          isOfficial:
              json['is_official'] ?? (json['source_type'] == 'document'),
          uploaderName:
              json['uploader_name'] ??
              (json['source_type'] == 'document' ? 'Official' : null),
          createdAt: json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
          updatedAt: json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : DateTime.now(),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to perform semantic search: $e');
    }
  }

  @override
  Future<void> incrementViewCount(String noteId) async {
    try {
      await supabase.rpc('increment_view_count', params: {'note_uuid': noteId});
    } catch (e) {
      // Log error but don't fail the main flow
      debugPrint('Failed to increment view count: $e');
    }
  }

  @override
  Future<void> incrementDownloadCount(String noteId) async {
    try {
      await supabase.rpc(
        'increment_download_count',
        params: {'note_uuid': noteId},
      );
    } catch (e) {
      // Log error but don't fail the main flow
      debugPrint('Failed to increment download count: $e');
    }
  }
}
