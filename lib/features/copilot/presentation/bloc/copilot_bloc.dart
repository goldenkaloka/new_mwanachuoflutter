import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/features/copilot/domain/usecases/download_note_for_offline.dart'
    as offline_usecase;
import 'package:mwanachuo/features/copilot/domain/usecases/get_course_notes.dart';
import 'package:mwanachuo/features/copilot/domain/usecases/query_note_with_rag.dart';
import 'package:mwanachuo/features/copilot/domain/usecases/semantic_search_notes.dart';
import 'package:mwanachuo/features/copilot/domain/usecases/upload_note.dart'
    as upload_usecase;
import 'package:mwanachuo/features/copilot/domain/repositories/copilot_repository.dart';
import 'copilot_event.dart';
import 'copilot_state.dart';

class CopilotBloc extends Bloc<CopilotEvent, CopilotState> {
  final GetCourseNotes getCourseNotes;
  final upload_usecase.UploadNote uploadNote;
  final QueryNoteWithRag queryNoteWithRag;
  final offline_usecase.DownloadNoteForOffline downloadNoteForOffline;
  final SemanticSearchNotes semanticSearchNotes;
  final CopilotRepository repository;

  CopilotBloc({
    required this.getCourseNotes,
    required this.uploadNote,
    required this.queryNoteWithRag,
    required this.downloadNoteForOffline,
    required this.semanticSearchNotes,
    required this.repository,
  }) : super(CopilotInitial()) {
    on<LoadCourseNotes>(_onLoadCourseNotes);
    on<UploadNote>(_onUploadNote);
    on<QueryWithRag>(_onQueryWithRag);
    on<LoadNoteDetails>(_onLoadNoteDetails);
    on<DownloadNoteForOffline>(_onDownloadNote);
    on<SearchNotes>(_onSearchNotes);
    on<ChangeFilter>(_onChangeFilter);
    on<RagResponseChunkReceived>(_onRagResponseChunkReceived);
    on<RagQueryComplete>(_onRagQueryComplete);
  }

  String _currentRagResponse = '';

  Future<void> _onLoadCourseNotes(
    LoadCourseNotes event,
    Emitter<CopilotState> emit,
  ) async {
    emit(CopilotLoading());

    final result = await getCourseNotes(
      courseId: event.courseId,
      filterBy: event.filterBy,
    );

    final downloadedResult = await repository.getDownloadedNotes(
      event.courseId,
    );

    result.fold((failure) => emit(CopilotError(message: failure.message)), (
      notes,
    ) {
      final downloadedNotes = downloadedResult.getOrElse(() => []);
      emit(
        CopilotNotesLoaded(
          notes: notes,
          downloadedNotes: downloadedNotes,
          currentFilter: event.filterBy,
        ),
      );
    });
  }

  Future<void> _onUploadNote(
    UploadNote event,
    Emitter<CopilotState> emit,
  ) async {
    emit(const CopilotUploading(progress: 0));

    final file = File(event.filePath);
    final result = await uploadNote(
      file: file,
      noteId: event.noteId,
      courseId: event.courseId,
    );

    result.fold((failure) => emit(CopilotError(message: failure.message)), (
      analysisResult,
    ) {
      emit(CopilotUploadSuccess(analysisResult: analysisResult));
      // Refresh the notes list so the new note appears on the dashboard
      add(LoadCourseNotes(courseId: event.courseId));
    });
  }

  Future<void> _onQueryWithRag(
    QueryWithRag event,
    Emitter<CopilotState> emit,
  ) async {
    _currentRagResponse = '';
    emit(const CopilotRagQuerying(currentResponse: ''));

    try {
      final stream = queryNoteWithRag(
        question: event.question,
        noteId: event.noteId,
        courseId: event.courseId,
      );

      await for (var chunk in stream) {
        add(RagResponseChunkReceived(chunk));
      }

      add(const RagQueryComplete());
    } catch (e) {
      emit(CopilotError(message: e.toString()));
    }
  }

  void _onRagResponseChunkReceived(
    RagResponseChunkReceived event,
    Emitter<CopilotState> emit,
  ) {
    _currentRagResponse += event.chunk;
    emit(CopilotRagQuerying(currentResponse: _currentRagResponse));
  }

  void _onRagQueryComplete(RagQueryComplete event, Emitter<CopilotState> emit) {
    emit(CopilotRagQueryComplete(fullResponse: _currentRagResponse));
  }

  Future<void> _onLoadNoteDetails(
    LoadNoteDetails event,
    Emitter<CopilotState> emit,
  ) async {
    emit(CopilotLoading());

    try {
      final noteResult = await repository.getNoteById(event.noteId);
      final conceptsResult = await repository.getNoteConcepts(event.noteId);
      final flashcardsResult = await repository.getNoteFlashcards(event.noteId);
      final tagsResult = await repository.getNoteTags(event.noteId);
      final isDownloaded = await repository.isNoteDownloaded(event.noteId);
      final localFilePath = isDownloaded
          ? await repository.getLocalFilePath(event.noteId)
          : null;

      noteResult.fold(
        (failure) => emit(CopilotError(message: failure.message)),
        (note) {
          final concepts = conceptsResult.getOrElse(() => []);
          final flashcards = flashcardsResult.getOrElse(() => []);
          final tags = tagsResult.getOrElse(() => []);

          emit(
            CopilotNoteDetailsLoaded(
              note: note,
              concepts: concepts,
              flashcards: flashcards,
              tags: tags,
              isDownloaded: isDownloaded,
              localFilePath: localFilePath,
            ),
          );
        },
      );
    } catch (e) {
      emit(CopilotError(message: e.toString()));
    }
  }

  Future<void> _onDownloadNote(
    DownloadNoteForOffline event,
    Emitter<CopilotState> emit,
  ) async {
    emit(CopilotDownloading(noteId: event.noteId));

    final result = await downloadNoteForOffline(event.noteId);

    result.fold(
      (failure) => emit(CopilotError(message: failure.message)),
      (filePath) => emit(CopilotDownloadSuccess(filePath: filePath)),
    );
  }

  Future<void> _onSearchNotes(
    SearchNotes event,
    Emitter<CopilotState> emit,
  ) async {
    emit(CopilotLoading());

    final result = await semanticSearchNotes(
      query: event.query,
      courseId: event.courseId,
    );

    result.fold(
      (failure) => emit(CopilotError(message: failure.message)),
      (results) =>
          emit(CopilotSearchResults(results: results, query: event.query)),
    );
  }

  void _onChangeFilter(ChangeFilter event, Emitter<CopilotState> emit) {
    if (state is CopilotNotesLoaded) {
      final currentState = state as CopilotNotesLoaded;
      emit(currentState.copyWith(currentFilter: event.filter));
    }
  }
}
