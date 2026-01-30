import 'package:mwanachuo/features/shared/university/domain/entities/university_entity.dart';

/// University model for the data layer
class UniversityModel extends UniversityEntity {
  const UniversityModel({
    required super.id,
    required super.name,
    required super.shortName,
    required super.location,
    super.logoUrl,
    super.description,
    super.isActive,
  });

  /// Create a UniversityModel from JSON
  factory UniversityModel.fromJson(Map<String, dynamic> json) {
    return UniversityModel(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: (json['short_name'] as String?) ?? (json['name'] as String),
      location: json['location'] as String,
      logoUrl: json['logo_url'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Convert UniversityModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'short_name': shortName,
      'location': location,
      'logo_url': logoUrl,
      'description': description,
      'is_active': isActive,
    };
  }

  /// Create a UniversityModel from UniversityEntity
  factory UniversityModel.fromEntity(UniversityEntity entity) {
    return UniversityModel(
      id: entity.id,
      name: entity.name,
      shortName: entity.shortName,
      location: entity.location,
      logoUrl: entity.logoUrl,
      description: entity.description,
      isActive: entity.isActive,
    );
  }
}
