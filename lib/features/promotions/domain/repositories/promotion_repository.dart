import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/promotions/domain/entities/promotion_entity.dart';

abstract class PromotionRepository {
  Future<Either<Failure, List<PromotionEntity>>> getActivePromotions();
  Future<Either<Failure, PromotionEntity>> getPromotionById(String promotionId);
  Future<Either<Failure, PromotionEntity>> createPromotion({
    required String title,
    required String subtitle,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    File? image,
    File? video,
    String? targetUrl,
    List<String>? terms,
    String type = 'banner',
    int priority = 0,
    String buttonText = 'Shop Now',
  });
}
