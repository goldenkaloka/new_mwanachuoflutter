import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../domain/entities/course.dart';

abstract class MwanachuomindEvent extends Equatable {
  const MwanachuomindEvent();

  @override
  List<Object> get props => [];
}

class CreateCourse extends MwanachuomindEvent {
  final String code;
  final String name;
  final String universityId;

  const CreateCourse({
    required this.code,
    required this.name,
    required this.universityId,
  });

  @override
  List<Object> get props => [code, name, universityId];
}

class LoadUniversityCourses extends MwanachuomindEvent {
  final String universityId;

  const LoadUniversityCourses(this.universityId);

  @override
  List<Object> get props => [universityId];
}

class SelectCourse extends MwanachuomindEvent {
  final Course course;

  const SelectCourse(this.course);

  @override
  List<Object> get props => [course];
}

class LoadChatHistory extends MwanachuomindEvent {
  final String userId;
  final String courseId;

  const LoadChatHistory({required this.userId, required this.courseId});

  @override
  List<Object> get props => [userId, courseId];
}

class UploadDocument extends MwanachuomindEvent {
  final String title;
  final File file;

  const UploadDocument(this.title, this.file);

  @override
  List<Object> get props => [title, file];
}

class SendQuery extends MwanachuomindEvent {
  final String query;
  final String? documentId;

  const SendQuery(this.query, {this.documentId});

  @override
  List<Object> get props => [query];
}

class LoadEnrolledCourse extends MwanachuomindEvent {
  final String userId;

  const LoadEnrolledCourse(this.userId);

  @override
  List<Object> get props => [userId];
}

class EnrollInCourse extends MwanachuomindEvent {
  final String userId;
  final String courseId;

  const EnrollInCourse({required this.userId, required this.courseId});

  @override
  List<Object> get props => [userId, courseId];
}

class LoadCourseDocuments extends MwanachuomindEvent {
  final String courseId;

  const LoadCourseDocuments(this.courseId);

  @override
  List<Object> get props => [courseId];
}
