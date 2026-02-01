import 'package:equatable/equatable.dart';

class PromotionEntity extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String? imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? targetUrl;
  final List<String>? terms;
  final DateTime createdAt;
  final String type; // 'banner' or 'video'
  final String? videoUrl;
  final int priority;
  final String buttonText;

  const PromotionEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    this.imageUrl,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.targetUrl,
    this.terms,
    required this.createdAt,
    this.type = 'banner',
    this.videoUrl,
    this.priority = 0,
    this.buttonText = 'Shop Now',
  });

  bool get isValid {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    description,
    imageUrl,
    startDate,
    endDate,
    isActive,
    targetUrl,
    terms,
    createdAt,
    type,
    videoUrl,
    priority,
    buttonText,
  ];
}
