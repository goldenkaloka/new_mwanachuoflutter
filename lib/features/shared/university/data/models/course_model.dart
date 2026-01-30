import 'package:mwanachuo/features/shared/university/domain/entities/course_entity.dart';

class CourseModel extends CourseEntity {
  const CourseModel({
    required super.id,
    required super.universityId,
    required super.name,
    required super.code,
    super.description,
    required super.createdAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String,
      universityId: json['university_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'university_id': universityId,
      'name': name,
      'code': code,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
