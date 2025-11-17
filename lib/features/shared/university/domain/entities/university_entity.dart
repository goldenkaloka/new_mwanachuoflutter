import 'package:equatable/equatable.dart';

/// University entity representing a university in the domain layer
class UniversityEntity extends Equatable {
  final String id;
  final String name;
  final String shortName;
  final String location;
  final String? logoUrl;
  final String? description;
  final bool isActive;

  const UniversityEntity({
    required this.id,
    required this.name,
    required this.shortName,
    required this.location,
    this.logoUrl,
    this.description,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        shortName,
        location,
        logoUrl,
        description,
        isActive,
      ];
}


