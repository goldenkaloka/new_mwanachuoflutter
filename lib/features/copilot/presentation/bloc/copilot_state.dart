import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/copilot/domain/entities/note_entity.dart';
import 'package:mwanachuo/features/copilot/domain/entities/concept_entity.dart';
import 'package:mwanachuo/features/copilot/domain/entities/flashcard_entity.dart';
import 'package:mwanachuo/features/copilot/domain/entities/tag_entity.dart';

abstract class CopilotState extends Equatable {
  const CopilotState();

  @override
  List<Object?> get props => [];
}

class CopilotInitial extends CopilotState {}

class CopilotLoading extends CopilotState {}

class CopilotNotesLoaded extends CopilotState {
  final List<NoteEntity> notes;
  final List<NoteEntity> downloadedNotes;
  final String? currentFilter;

  const CopilotNotesLoaded({
    required this.notes,
    this.downloadedNotes = const [],
    this.currentFilter,
  });

  @override
  List<Object?> get props => [notes, downloadedNotes, currentFilter];

  CopilotNotesLoaded copyWith({
    List<NoteEntity>? notes,
    List<NoteEntity>? downloadedNotes,
    String? currentFilter,
  }) {
    return CopilotNotesLoaded(
      notes: notes ?? this.notes,
      downloadedNotes: downloadedNotes ?? this.downloadedNotes,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}

class CopilotNoteDetailsLoaded extends CopilotState {
  final NoteEntity note;
  final List<ConceptEntity> concepts;
  final List<FlashcardEntity> flashcards;
  final List<TagEntity> tags;
  final bool isDownloaded;
  final String? localFilePath;

  const CopilotNoteDetailsLoaded({
    required this.note,
    required this.concepts,
    required this.flashcards,
    required this.tags,
    required this.isDownloaded,
    this.localFilePath,
  });

  @override
  List<Object?> get props => [
    note,
    concepts,
    flashcards,
    tags,
    isDownloaded,
    localFilePath,
  ];
}

class CopilotUploading extends CopilotState {
  final int progress; // 0-100

  const CopilotUploading({required this.progress});

  @override
  List<Object?> get props => [progress];
}

class CopilotUploadSuccess extends CopilotState {
  final Map<String, dynamic> analysisResult;

  const CopilotUploadSuccess({required this.analysisResult});

  @override
  List<Object?> get props => [analysisResult];
}

class CopilotRagQuerying extends CopilotState {
  final String currentResponse;

  const CopilotRagQuerying({required this.currentResponse});

  @override
  List<Object?> get props => [currentResponse];
}

class CopilotRagQueryComplete extends CopilotState {
  final String fullResponse;

  const CopilotRagQueryComplete({required this.fullResponse});

  @override
  List<Object?> get props => [fullResponse];
}

class CopilotDownloading extends CopilotState {
  final String noteId;

  const CopilotDownloading({required this.noteId});

  @override
  List<Object?> get props => [noteId];
}

class CopilotDownloadSuccess extends CopilotState {
  final String filePath;

  const CopilotDownloadSuccess({required this.filePath});

  @override
  List<Object?> get props => [filePath];
}

class CopilotSearchResults extends CopilotState {
  final List<NoteEntity> results;
  final String query;

  const CopilotSearchResults({required this.results, required this.query});

  @override
  List<Object?> get props => [results, query];
}

class CopilotError extends CopilotState {
  final String message;

  const CopilotError({required this.message});

  @override
  List<Object?> get props => [message];
}
