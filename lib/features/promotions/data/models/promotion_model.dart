import 'package:mwanachuo/features/promotions/domain/entities/promotion_entity.dart';

class PromotionModel extends PromotionEntity {
  const PromotionModel({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.description,
    super.imageUrl,
    required super.startDate,
    required super.endDate,
    super.isActive,
    super.targetUrl,
    super.terms,
    required super.createdAt,
    super.type,
    super.videoUrl,
    super.priority,
    super.buttonText,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      targetUrl: json['target_url'] as String?,
      terms: json['terms'] != null
          ? List<String>.from(json['terms'] as List)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      type: json['type'] as String? ?? 'banner',
      videoUrl: json['video_url'] as String?,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      buttonText: json['button_text'] as String? ?? 'Shop Now',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'image_url': imageUrl,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'target_url': targetUrl,
      'terms': terms,
      'created_at': createdAt.toIso8601String(),
      'type': type,
      'video_url': videoUrl,
      'priority': priority,
      'button_text': buttonText,
    };
  }
}
