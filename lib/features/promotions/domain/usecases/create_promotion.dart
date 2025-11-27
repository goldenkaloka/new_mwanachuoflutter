import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/promotions/domain/entities/promotion_entity.dart';
import 'package:mwanachuo/features/promotions/domain/repositories/promotion_repository.dart';

class CreatePromotion implements UseCase<PromotionEntity, CreatePromotionParams> {
  final PromotionRepository repository;

  CreatePromotion(this.repository);

  @override
  Future<Either<Failure, PromotionEntity>> call(CreatePromotionParams params) async {
    return await repository.createPromotion(
      title: params.title,
      subtitle: params.subtitle,
      description: params.description,
      startDate: params.startDate,
      endDate: params.endDate,
      image: params.image,
      targetUrl: params.targetUrl,
      terms: params.terms,
    );
  }
}

class CreatePromotionParams extends Equatable {
  final String title;
  final String subtitle;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final File? image;
  final String? targetUrl;
  final List<String>? terms;

  const CreatePromotionParams({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.image,
    this.targetUrl,
    this.terms,
  });

  @override
  List<Object?> get props => [
        title,
        subtitle,
        description,
        startDate,
        endDate,
        image,
        targetUrl,
        terms,
      ];
}

