import 'package:equatable/equatable.dart';

class CourseEntity extends Equatable {
  final String id;
  final String universityId;
  final String name;
  final String code;
  final String? description;
  final DateTime createdAt;

  const CourseEntity({
    required this.id,
    required this.universityId,
    required this.name,
    required this.code,
    this.description,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    universityId,
    name,
    code,
    description,
    createdAt,
  ];
}
