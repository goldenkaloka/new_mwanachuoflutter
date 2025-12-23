import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/document.dart';

enum MwanachuomindStatus { initial, loading, success, failure }

class MwanachuomindState extends Equatable {
  final MwanachuomindStatus status;
  final List<Course> courses;
  final Course? selectedCourse;
  final Course? enrolledCourse;
  final List<ChatMessage> chatHistory;
  final List<Document> courseDocuments;
  final String? errorMessage;
  final bool isUploading;
  final String? sessionId;

  const MwanachuomindState({
    this.status = MwanachuomindStatus.initial,
    this.courses = const [],
    this.selectedCourse,
    this.enrolledCourse,
    this.chatHistory = const [],
    this.courseDocuments = const [],
    this.errorMessage,
    this.isUploading = false,
    this.sessionId,
  });

  MwanachuomindState copyWith({
    MwanachuomindStatus? status,
    List<Course>? courses,
    Course? selectedCourse,
    Course? enrolledCourse,
    List<ChatMessage>? chatHistory,
    List<Document>? courseDocuments,
    String? errorMessage,
    bool? isUploading,
    String? sessionId,
  }) {
    return MwanachuomindState(
      status: status ?? this.status,
      courses: courses ?? this.courses,
      selectedCourse: selectedCourse ?? this.selectedCourse,
      enrolledCourse: enrolledCourse ?? this.enrolledCourse,
      chatHistory: chatHistory ?? this.chatHistory,
      courseDocuments: courseDocuments ?? this.courseDocuments,
      errorMessage: errorMessage ?? this.errorMessage,
      isUploading: isUploading ?? this.isUploading,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    courses,
    selectedCourse,
    enrolledCourse,
    chatHistory,
    courseDocuments,
    errorMessage,
    isUploading,
    sessionId,
  ];
}
