import 'dart:io';
import 'package:equatable/equatable.dart';

/// Base class for all product events
abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

/// Load products event
class LoadProductsEvent extends ProductEvent {
  final String? category;
  final String? universityId;
  final String? sellerId;
  final bool? isFeatured;
  final int? limit;
  final int? offset;

  const LoadProductsEvent({
    this.category,
    this.universityId,
    this.sellerId,
    this.isFeatured,
    this.limit,
    this.offset,
  });

  @override
  List<Object?> get props => [
        category,
        universityId,
        sellerId,
        isFeatured,
        limit,
        offset,
      ];
}

/// Load product by ID event
class LoadProductByIdEvent extends ProductEvent {
  final String productId;

  const LoadProductByIdEvent({required this.productId});

  @override
  List<Object?> get props => [productId];
}

/// Load my products event
class LoadMyProductsEvent extends ProductEvent {
  final int? limit;
  final int? offset;

  const LoadMyProductsEvent({this.limit, this.offset});

  @override
  List<Object?> get props => [limit, offset];
}

/// Create product event
class CreateProductEvent extends ProductEvent {
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final List<File> images;
  final String location;
  final Map<String, dynamic>? metadata;

  const CreateProductEvent({
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

/// Update product event
class UpdateProductEvent extends ProductEvent {
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

  const UpdateProductEvent({
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

/// Delete product event
class DeleteProductEvent extends ProductEvent {
  final String productId;

  const DeleteProductEvent({required this.productId});

  @override
  List<Object?> get props => [productId];
}

/// Increment view count event
class IncrementViewCountEvent extends ProductEvent {
  final String productId;

  const IncrementViewCountEvent({required this.productId});

  @override
  List<Object?> get props => [productId];
}

/// Load more products event (pagination)
class LoadMoreProductsEvent extends ProductEvent {
  final int offset;
  final String? category;
  final String? universityId;
  final bool? isFeatured;

  const LoadMoreProductsEvent({
    required this.offset,
    this.category,
    this.universityId,
    this.isFeatured,
  });

  @override
  List<Object?> get props => [offset, category, universityId, isFeatured];
}

