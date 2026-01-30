import 'package:hive/hive.dart';
import 'package:mwanachuo/features/copilot/data/models/note_model.dart';

abstract class CopilotLocalDataSource {
  /// Cache note locally
  Future<void> cacheNote(NoteModel note);

  /// Get cached note
  Future<NoteModel?> getCachedNote(String noteId);

  /// Get all cached notes for a course
  Future<List<NoteModel>> getCachedCourseNotes(String courseId);

  /// Mark note as downloaded
  Future<void> markAsDownloaded(String noteId, String localFilePath);

  /// Check if note is downloaded
  Future<bool> isNoteDownloaded(String noteId);

  /// Get local file path for downloaded note
  Future<String?> getLocalFilePath(String noteId);

  /// Delete downloaded note
  Future<void> deleteDownloadedNote(String noteId);

  /// Clear all cached data
  Future<void> clearCache();
}

class CopilotLocalDataSourceImpl implements CopilotLocalDataSource {
  static const String notesBoxName = 'copilot_notes';
  static const String downloadsBoxName = 'copilot_downloads';

  late Box<Map<dynamic, dynamic>> notesBox;
  late Box<Map<dynamic, dynamic>> downloadsBox;

  Future<void> init() async {
    notesBox = await Hive.openBox<Map>(notesBoxName);
    downloadsBox = await Hive.openBox<Map>(downloadsBoxName);
  }

  @override
  Future<void> cacheNote(NoteModel note) async {
    await notesBox.put(note.id, note.toJson());
  }

  @override
  Future<NoteModel?> getCachedNote(String noteId) async {
    final json = notesBox.get(noteId);
    if (json == null) return null;
    return NoteModel.fromJson(Map<String, dynamic>.from(json));
  }

  @override
  Future<List<NoteModel>> getCachedCourseNotes(String courseId) async {
    final allNotes = notesBox.values;
    return allNotes
        .where((json) => json['course_id'] == courseId)
        .map((json) => NoteModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  @override
  Future<void> markAsDownloaded(String noteId, String localFilePath) async {
    await downloadsBox.put(noteId, {
      'note_id': noteId,
      'local_path': localFilePath,
      'downloaded_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<bool> isNoteDownloaded(String noteId) async {
    return downloadsBox.containsKey(noteId);
  }

  @override
  Future<String?> getLocalFilePath(String noteId) async {
    final data = downloadsBox.get(noteId);
    return data?['local_path'] as String?;
  }

  @override
  Future<void> deleteDownloadedNote(String noteId) async {
    await downloadsBox.delete(noteId);
  }

  @override
  Future<void> clearCache() async {
    await notesBox.clear();
    await downloadsBox.clear();
  }
}
