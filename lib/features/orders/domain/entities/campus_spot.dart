import 'package:equatable/equatable.dart';

class CampusSpot extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? universityId;
  final String? icon;

  const CampusSpot({
    required this.id,
    required this.name,
    this.description,
    this.universityId,
    this.icon,
  });

  @override
  List<Object?> get props => [id, name, description, universityId, icon];
}
