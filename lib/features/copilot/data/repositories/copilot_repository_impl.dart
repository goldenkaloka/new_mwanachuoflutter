import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/copilot/data/datasources/copilot_local_data_source.dart';
import 'package:mwanachuo/features/copilot/data/datasources/copilot_remote_data_source.dart';
import 'package:mwanachuo/features/copilot/domain/entities/concept_entity.dart';
import 'package:mwanachuo/features/copilot/domain/entities/flashcard_entity.dart';
import 'package:mwanachuo/features/copilot/domain/entities/note_entity.dart';
import 'package:mwanachuo/features/copilot/domain/entities/tag_entity.dart';
import 'package:mwanachuo/features/copilot/domain/repositories/copilot_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class CopilotRepositoryImpl implements CopilotRepository {
  final CopilotRemoteDataSource remoteDataSource;
  final CopilotLocalDataSource localDataSource;

  CopilotRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, Map<String, dynamic>>> uploadAndAnalyze({
    required File file,
    required String noteId,
    required String courseId,
    String? title,
    int? year,
    int? semester,
  }) async {
    try {
      final result = await remoteDataSource.uploadAndAnalyze(
        file: file,
        noteId: noteId,
        courseId: courseId,
        title: title,
        year: year,
        semester: semester,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NoteEntity>>> getCourseNotes({
    required String courseId,
    String? filterBy,
    int? year,
    int? semester,
  }) async {
    try {
      final notes = await remoteDataSource.getCourseNotes(
        courseId: courseId,
        filterBy: filterBy,
        year: year,
        semester: semester,
      );

      // Cache notes locally
      for (var note in notes) {
        await localDataSource.cacheNote(note);
      }

      return Right(notes);
    } catch (e) {
      // Try local cache if remote fails
      try {
        final cachedNotes = await localDataSource.getCachedCourseNotes(
          courseId,
        );
        if (cachedNotes.isNotEmpty) {
          return Right(cachedNotes);
        }
      } catch (_) {}

      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NoteEntity>> getNoteById(String noteId) async {
    try {
      final note = await remoteDataSource.getNoteById(noteId);
      await localDataSource.cacheNote(note);
      return Right(note);
    } catch (e) {
      // Try local cache
      try {
        final cachedNote = await localDataSource.getCachedNote(noteId);
        if (cachedNote != null) {
          return Right(cachedNote);
        }
      } catch (_) {}

      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ConceptEntity>>> getNoteConcepts(
    String noteId,
  ) async {
    try {
      final concepts = await remoteDataSource.getNoteConcepts(noteId);
      return Right(concepts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FlashcardEntity>>> getNoteFlashcards(
    String noteId,
  ) async {
    try {
      final flashcards = await remoteDataSource.getNoteFlashcards(noteId);
      return Right(flashcards);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TagEntity>>> getNoteTags(String noteId) async {
    try {
      final tags = await remoteDataSource.getNoteTags(noteId);
      return Right(tags);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<String> queryNoteWithRag({
    required String question,
    required String courseId,
    String? noteId,
    List<Map<String, dynamic>>? history,
  }) {
    return remoteDataSource.queryWithRag(
      question: question,
      noteId: noteId,
      courseId: courseId,
      history: history,
    );
  }

  @override
  Future<Either<Failure, List<NoteEntity>>> semanticSearch({
    required String query,
    required String courseId,
    int limit = 10,
  }) async {
    try {
      final results = await remoteDataSource.semanticSearch(
        query: query,
        courseId: courseId,
        limit: limit,
      );
      return Right(results);
    } catch (e) {
      // Fallback to local keyword search if remote fails (quota, offline, etc)
      try {
        final cachedNotes = await localDataSource.getCachedCourseNotes(
          courseId,
        );
        final lowercaseQuery = query.toLowerCase();

        final filteredNotes = cachedNotes.where((note) {
          final titleMatch = note.title.toLowerCase().contains(lowercaseQuery);
          final descMatch =
              note.description?.toLowerCase().contains(lowercaseQuery) ?? false;
          return titleMatch || descMatch;
        }).toList();

        return Right(filteredNotes);
      } catch (cacheError) {
        return Left(ServerFailure(e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, String>> downloadNoteForOffline(String noteId) async {
    try {
      // Get note details
      final note = await remoteDataSource.getNoteById(noteId);

      // Download file
      final response = await http.get(Uri.parse(note.fileUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download file');
      }

      // Save to local storage
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${note.id}.${note.fileType.split('/').last}';
      final filePath = '${directory.path}/copilot_notes/$fileName';

      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsBytes(response.bodyBytes);

      // Mark as downloaded
      await localDataSource.markAsDownloaded(noteId, filePath);

      return Right(filePath);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<bool> isNoteDownloaded(String noteId) async {
    return await localDataSource.isNoteDownloaded(noteId);
  }

  @override
  Future<String?> getLocalFilePath(String noteId) async {
    return await localDataSource.getLocalFilePath(noteId);
  }

  @override
  Future<Either<Failure, List<NoteEntity>>> getDownloadedNotes(
    String courseId,
  ) async {
    try {
      final downloadedNotes = await localDataSource.getCachedCourseNotes(
        courseId,
      );
      // Filter only those that are actually in downloadsBox
      final List<NoteEntity> actuallyDownloaded = [];
      for (var note in downloadedNotes) {
        if (await localDataSource.isNoteDownloaded(note.id)) {
          actuallyDownloaded.add(note);
        }
      }
      return Right(actuallyDownloaded);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDownloadedNote(String noteId) async {
    try {
      final filePath = await localDataSource.getLocalFilePath(noteId);
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
        await localDataSource.deleteDownloadedNote(noteId);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> incrementViewCount(String noteId) async {
    try {
      await remoteDataSource.incrementViewCount(noteId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> incrementDownloadCount(String noteId) async {
    try {
      await remoteDataSource.incrementDownloadCount(noteId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
