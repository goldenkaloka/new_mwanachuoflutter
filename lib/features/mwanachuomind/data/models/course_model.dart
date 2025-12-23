import '../../domain/entities/course.dart';

class CourseModel extends Course {
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
      id: json['id'],
      universityId: json['university_id'],
      name: json['name'],
      code: json['code'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
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
