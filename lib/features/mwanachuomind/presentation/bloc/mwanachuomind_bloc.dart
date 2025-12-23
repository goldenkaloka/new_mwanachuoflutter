import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/mwanachuomind_repository.dart';
import '../../domain/usecases/create_course_usecase.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/get_university_courses_usecase.dart';
import '../../domain/usecases/send_query_usecase.dart';
import '../../domain/usecases/upload_document_usecase.dart';

import 'mwanachuomind_event.dart';
import 'mwanachuomind_state.dart';

class MwanachuomindBloc extends Bloc<MwanachuomindEvent, MwanachuomindState> {
  final GetUniversityCoursesUseCase getUniversityCoursesUseCase;
  final UploadDocumentUseCase uploadDocumentUseCase;
  final SendQueryUseCase sendQueryUseCase;
  final CreateCourseUseCase createCourseUseCase;
  final MwanachuomindRepository repository;

  MwanachuomindBloc({
    required this.getUniversityCoursesUseCase,
    required this.uploadDocumentUseCase,
    required this.sendQueryUseCase,
    required this.createCourseUseCase,
    required this.repository,
  }) : super(const MwanachuomindState()) {
    on<LoadUniversityCourses>(_onLoadUniversityCourses);
    on<SelectCourse>(_onSelectCourse);
    on<LoadChatHistory>(_onLoadChatHistory);
    on<UploadDocument>(_onUploadDocument);
    on<SendQuery>(_onSendQuery);
    on<CreateCourse>(_onCreateCourse);
    on<LoadEnrolledCourse>(_onLoadEnrolledCourse);
    on<EnrollInCourse>(_onEnrollInCourse);
    on<LoadCourseDocuments>(_onLoadCourseDocuments);
  }

  Future<void> _onLoadUniversityCourses(
    LoadUniversityCourses event,
    Emitter<MwanachuomindState> emit,
  ) async {
    emit(state.copyWith(status: MwanachuomindStatus.loading));
    try {
      final courses = await getUniversityCoursesUseCase(event.universityId);
      emit(
        state.copyWith(status: MwanachuomindStatus.success, courses: courses),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: MwanachuomindStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onSelectCourse(SelectCourse event, Emitter<MwanachuomindState> emit) {
    emit(
      state.copyWith(
        selectedCourse: event.course,
        chatHistory: [],
        sessionId: null,
      ),
    );
  }

  Future<void> _onLoadChatHistory(
    LoadChatHistory event,
    Emitter<MwanachuomindState> emit,
  ) async {
    emit(state.copyWith(status: MwanachuomindStatus.loading));
    try {
      final sessionId = await repository.getOrCreateSession(
        event.userId,
        event.courseId,
      );
      final messages = await repository.getSessionMessages(sessionId);

      final chatHistory = messages
          .map(
            (m) => ChatMessage(
              id: m['id'] as String,
              content: m['content'] as String,
              sender: m['sender'] == 'user'
                  ? MessageSender.user
                  : MessageSender.ai,
              timestamp: DateTime.parse(m['created_at'] as String),
            ),
          )
          .toList();

      emit(
        state.copyWith(
          status: MwanachuomindStatus.success,
          sessionId: sessionId,
          chatHistory: chatHistory,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: MwanachuomindStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUploadDocument(
    UploadDocument event,
    Emitter<MwanachuomindState> emit,
  ) async {
    if (state.selectedCourse == null) return;
    emit(state.copyWith(isUploading: true));
    try {
      await uploadDocumentUseCase(
        courseId: state.selectedCourse!.id,
        title: event.title,
        file: event.file,
      );
      emit(state.copyWith(isUploading: false));
      // Reload documents after upload
      add(LoadCourseDocuments(state.selectedCourse!.id));
    } catch (e) {
      emit(
        state.copyWith(
          isUploading: false,
          errorMessage: "Upload failed: ${e.toString()}",
        ),
      );
    }
  }

  Future<void> _onSendQuery(
    SendQuery event,
    Emitter<MwanachuomindState> emit,
  ) async {
    if (state.selectedCourse == null || state.sessionId == null) return;

    final userMessage = ChatMessage(
      id: DateTime.now().toString(),
      content: event.query,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    final updatedHistory = List<ChatMessage>.from(state.chatHistory)
      ..add(userMessage);

    emit(
      state.copyWith(
        chatHistory: updatedHistory,
        status: MwanachuomindStatus.loading,
      ),
    );

    try {
      await repository.saveMessage(state.sessionId!, event.query, 'user');
    } catch (_) {}

    try {
      final apiHistory = state.chatHistory
          .map(
            (m) => {
              'role': m.sender == MessageSender.user ? 'user' : 'model',
              'parts': m.content,
            },
          )
          .toList();

      final stream = repository.chatStream(
        query: event.query,
        courseId: state.selectedCourse!.id,
        history: apiHistory,
        documentId: event.documentId,
      );

      String fullResponse = "";

      await for (final chunk in stream) {
        fullResponse += chunk;
      }

      final aiMessage = ChatMessage(
        id: DateTime.now().toString(),
        content: fullResponse,
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      );

      try {
        await repository.saveMessage(state.sessionId!, fullResponse, 'ai');
      } catch (_) {}

      emit(
        state.copyWith(
          chatHistory: List.from(updatedHistory)..add(aiMessage),
          status: MwanachuomindStatus.success,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: MwanachuomindStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onCreateCourse(
    CreateCourse event,
    Emitter<MwanachuomindState> emit,
  ) async {
    try {
      await createCourseUseCase(
        code: event.code,
        name: event.name,
        universityId: event.universityId,
      );
      add(LoadUniversityCourses(event.universityId));
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: "Failed to create course: ${e.toString()}",
        ),
      );
    }
  }

  Future<void> _onLoadEnrolledCourse(
    LoadEnrolledCourse event,
    Emitter<MwanachuomindState> emit,
  ) async {
    emit(state.copyWith(status: MwanachuomindStatus.loading));
    try {
      final course = await repository.getEnrolledCourse(event.userId);
      emit(
        state.copyWith(
          status: MwanachuomindStatus.success,
          enrolledCourse: course,
          selectedCourse: course,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: MwanachuomindStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onEnrollInCourse(
    EnrollInCourse event,
    Emitter<MwanachuomindState> emit,
  ) async {
    try {
      await repository.setEnrolledCourse(event.userId, event.courseId);
      // Reload to confirm enrollment
      add(LoadEnrolledCourse(event.userId));
    } catch (e) {
      emit(state.copyWith(errorMessage: "Failed to enroll: ${e.toString()}"));
    }
  }

  Future<void> _onLoadCourseDocuments(
    LoadCourseDocuments event,
    Emitter<MwanachuomindState> emit,
  ) async {
    try {
      final documents = await repository.getCourseDocuments(event.courseId);
      emit(state.copyWith(courseDocuments: documents));
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: "Failed to load documents: ${e.toString()}",
        ),
      );
    }
  }
}
