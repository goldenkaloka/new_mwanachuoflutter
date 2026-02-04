import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/copilot/domain/entities/note_entity.dart';
import 'package:mwanachuo/features/copilot/domain/entities/concept_entity.dart';
import 'package:mwanachuo/features/copilot/domain/entities/flashcard_entity.dart';
import 'package:mwanachuo/features/copilot/domain/entities/tag_entity.dart';

abstract class CopilotRepository {
  /// Upload and analyze a note with AI
  Future<Either<Failure, Map<String, dynamic>>> uploadAndAnalyze({
    required File file,
    required String noteId,
    required String courseId,
    String? title,
    int? year,
    int? semester,
  });

  /// Get all notes for a course
  Future<Either<Failure, List<NoteEntity>>> getCourseNotes({
    required String courseId,
    String? filterBy, // 'official', 'my_notes', 'shared'
    int? year,
    int? semester,
  });

  /// Get note by ID with concepts and tags
  Future<Either<Failure, NoteEntity>> getNoteById(String noteId);

  /// Get AI-extracted concepts for a note
  Future<Either<Failure, List<ConceptEntity>>> getNoteConcepts(String noteId);

  /// Get AI-generated flashcards for a note
  Future<Either<Failure, List<FlashcardEntity>>> getNoteFlashcards(
    String noteId,
  );

  /// Get tags for a note
  Future<Either<Failure, List<TagEntity>>> getNoteTags(String noteId);

  /// Query note with RAG (streaming)
  Stream<String> queryNoteWithRag({
    required String question,
    required String courseId,
    String? noteId,
    List<Map<String, dynamic>>? history,
  });

  /// Semantic search across notes
  Future<Either<Failure, List<NoteEntity>>> semanticSearch({
    required String query,
    required String courseId,
    int limit = 10,
  });

  /// Download note for offline access
  Future<Either<Failure, String>> downloadNoteForOffline(String noteId);

  /// Check if note is downloaded
  Future<bool> isNoteDownloaded(String noteId);

  /// Get local file path for a downloaded note
  Future<String?> getLocalFilePath(String noteId);

  /// Get all downloaded notes for a course
  Future<Either<Failure, List<NoteEntity>>> getDownloadedNotes(String courseId);

  /// Delete downloaded note
  Future<Either<Failure, void>> deleteDownloadedNote(String noteId);

  /// Increment view count
  Future<Either<Failure, void>> incrementViewCount(String noteId);

  /// Increment download count
  Future<Either<Failure, void>> incrementDownloadCount(String noteId);
}
