import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/products/domain/entities/product_entity.dart';
import 'package:mwanachuo/features/products/domain/repositories/product_repository.dart';

/// Use case for updating a product
class UpdateProduct implements UseCase<ProductEntity, UpdateProductParams> {
  final ProductRepository repository;

  UpdateProduct(this.repository);

  @override
  Future<Either<Failure, ProductEntity>> call(
    UpdateProductParams params,
  ) async {
    // Validate if provided
    if (params.title != null && params.title!.trim().isEmpty) {
      return Left(ValidationFailure('Title cannot be empty'));
    }
    if (params.description != null && params.description!.trim().isEmpty) {
      return Left(ValidationFailure('Description cannot be empty'));
    }
    if (params.price != null && params.price! <= 0) {
      return Left(ValidationFailure('Price must be greater than 0'));
    }

    return await repository.updateProduct(
      productId: params.productId,
      title: params.title?.trim(),
      description: params.description?.trim(),
      price: params.price,
      category: params.category,
      condition: params.condition,
      newImages: params.newImages,
      existingImages: params.existingImages,
      location: params.location?.trim(),
      isActive: params.isActive,
      metadata: params.metadata,
    );
  }
}

class UpdateProductParams extends Equatable {
  final String productId;
  final String? title;
  final String? description;
  final double? price;
  final String? category;
  final String? condition;
  final List<File>? newImages;
  final List<String>? existingImages;
  final String? location;
  final bool? isActive;
  final Map<String, dynamic>? metadata;

  const UpdateProductParams({
    required this.productId,
    this.title,
    this.description,
    this.price,
    this.category,
    this.condition,
    this.newImages,
    this.existingImages,
    this.location,
    this.isActive,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        productId,
        title,
        description,
        price,
        category,
        condition,
        newImages,
        existingImages,
        location,
        isActive,
        metadata,
      ];
}

