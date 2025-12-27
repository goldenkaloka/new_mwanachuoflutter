import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/chat_session.dart';

enum MwanachuomindStatus { initial, loading, success, failure }

class MwanachuomindState extends Equatable {
  final MwanachuomindStatus status;
  final List<Course> courses;
  final Course? selectedCourse;
  final Document? selectedDocument;
  final Course? enrolledCourse;
  final List<ChatMessage> chatHistory;
  final List<Document> courseDocuments;
  final String? errorMessage;
  final bool isUploading;
  final String? sessionId;
  final bool isGenerating;
  final List<ChatSession> sessions;

  const MwanachuomindState({
    this.status = MwanachuomindStatus.initial,
    this.courses = const [],
    this.selectedCourse,
    this.selectedDocument,
    this.enrolledCourse,
    this.chatHistory = const [],
    this.courseDocuments = const [],
    this.errorMessage,
    this.isUploading = false,
    this.sessionId,
    this.isGenerating = false,
    this.sessions = const [],
  });

  MwanachuomindState copyWith({
    MwanachuomindStatus? status,
    List<Course>? courses,
    Course? selectedCourse,
    Document? selectedDocument,
    Course? enrolledCourse,
    List<ChatMessage>? chatHistory,
    List<Document>? courseDocuments,
    String? errorMessage,
    bool? isUploading,
    String? sessionId,
    bool? isGenerating,
    List<ChatSession>? sessions,
  }) {
    return MwanachuomindState(
      status: status ?? this.status,
      courses: courses ?? this.courses,
      selectedCourse: selectedCourse ?? this.selectedCourse,
      selectedDocument: selectedDocument, // Allow null to clear
      enrolledCourse: enrolledCourse ?? this.enrolledCourse,
      chatHistory: chatHistory ?? this.chatHistory,
      courseDocuments: courseDocuments ?? this.courseDocuments,
      errorMessage: errorMessage ?? this.errorMessage,
      isUploading: isUploading ?? this.isUploading,
      sessionId: sessionId ?? this.sessionId,
      isGenerating: isGenerating ?? this.isGenerating,
      sessions: sessions ?? this.sessions,
    );
  }

  @override
  List<Object?> get props => [
    status,
    courses,
    selectedCourse,
    selectedDocument,
    enrolledCourse,
    chatHistory,
    courseDocuments,
    errorMessage,
    isUploading,
    sessionId,
    isGenerating,
    sessions,
  ];
}
