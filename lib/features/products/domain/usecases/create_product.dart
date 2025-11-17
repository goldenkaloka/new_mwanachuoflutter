import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/products/domain/entities/product_entity.dart';
import 'package:mwanachuo/features/products/domain/repositories/product_repository.dart';

/// Use case for creating a product
class CreateProduct implements UseCase<ProductEntity, CreateProductParams> {
  final ProductRepository repository;

  CreateProduct(this.repository);

  @override
  Future<Either<Failure, ProductEntity>> call(
    CreateProductParams params,
  ) async {
    // Validate
    if (params.title.trim().isEmpty) {
      return Left(ValidationFailure('Title cannot be empty'));
    }
    if (params.description.trim().isEmpty) {
      return Left(ValidationFailure('Description cannot be empty'));
    }
    if (params.price <= 0) {
      return Left(ValidationFailure('Price must be greater than 0'));
    }
    if (params.images.isEmpty) {
      return Left(ValidationFailure('At least one image is required'));
    }

    return await repository.createProduct(
      title: params.title.trim(),
      description: params.description.trim(),
      price: params.price,
      category: params.category,
      condition: params.condition,
      images: params.images,
      location: params.location.trim(),
      metadata: params.metadata,
    );
  }
}

class CreateProductParams extends Equatable {
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final List<File> images;
  final String location;
  final Map<String, dynamic>? metadata;

  const CreateProductParams({
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.images,
    required this.location,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        price,
        category,
        condition,
        images,
        location,
        metadata,
      ];
}

