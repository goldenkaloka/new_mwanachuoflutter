import 'package:mwanachuo/features/orders/domain/entities/campus_spot.dart';

class CampusSpotModel extends CampusSpot {
  const CampusSpotModel({
    required super.id,
    required super.name,
    super.description,
    super.universityId,
    super.icon,
  });

  factory CampusSpotModel.fromJson(Map<String, dynamic> json) {
    return CampusSpotModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      universityId: json['university_id'] as String?,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'university_id': universityId,
      'icon': icon,
    };
  }
}
