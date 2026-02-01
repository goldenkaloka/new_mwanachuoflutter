import 'package:equatable/equatable.dart';

abstract class CopilotEvent extends Equatable {
  const CopilotEvent();

  @override
  List<Object?> get props => [];
}

// Load course notes
class LoadCourseNotes extends CopilotEvent {
  final String courseId;
  final String? filterBy; // 'official', 'my_notes', 'shared'

  const LoadCourseNotes({required this.courseId, this.filterBy});

  @override
  List<Object?> get props => [courseId, filterBy];
}

// Upload note
class UploadNote extends CopilotEvent {
  final String filePath;
  final String noteId;
  final String courseId;

  const UploadNote({
    required this.filePath,
    required this.noteId,
    required this.courseId,
  });

  @override
  List<Object?> get props => [filePath, noteId, courseId];
}

// Query with RAG
class QueryWithRag extends CopilotEvent {
  final String question;
  final String? noteId;
  final String courseId;

  const QueryWithRag({
    required this.question,
    this.noteId,
    required this.courseId,
  });

  @override
  List<Object?> get props => [question, noteId, courseId];
}

// Load note details
class LoadNoteDetails extends CopilotEvent {
  final String noteId;

  const LoadNoteDetails(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

// Download note for offline
class DownloadNoteForOffline extends CopilotEvent {
  final String noteId;

  const DownloadNoteForOffline(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

// Semantic search
class SearchNotes extends CopilotEvent {
  final String query;
  final String courseId;

  const SearchNotes({required this.query, required this.courseId});

  @override
  List<Object?> get props => [query, courseId];
}

// Change filter
class ChangeFilter extends CopilotEvent {
  final String? filter;

  const ChangeFilter(this.filter);

  @override
  List<Object?> get props => [filter];
}

// RAG response chunk received
class RagResponseChunkReceived extends CopilotEvent {
  final String chunk;

  const RagResponseChunkReceived(this.chunk);

  @override
  List<Object?> get props => [chunk];
}

// RAG query complete
class RagQueryComplete extends CopilotEvent {
  const RagQueryComplete();
}
