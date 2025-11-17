import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/products/domain/entities/product_entity.dart';

/// Product repository interface
abstract class ProductRepository {
  /// Get all products
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    String? category,
    String? universityId,
    String? sellerId,
    bool? isFeatured,
    int? limit,
    int? offset,
  });

  /// Get a single product by ID
  Future<Either<Failure, ProductEntity>> getProductById(String productId);

  /// Get user's products (seller's listings)
  Future<Either<Failure, List<ProductEntity>>> getMyProducts({
    int? limit,
    int? offset,
  });

  /// Create a new product
  Future<Either<Failure, ProductEntity>> createProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    required List<File> images,
    required String location,
    Map<String, dynamic>? metadata,
  });

  /// Update a product
  Future<Either<Failure, ProductEntity>> updateProduct({
    required String productId,
    String? title,
    String? description,
    double? price,
    String? category,
    String? condition,
    List<File>? newImages,
    List<String>? existingImages,
    String? location,
    bool? isActive,
    Map<String, dynamic>? metadata,
  });

  /// Delete a product
  Future<Either<Failure, void>> deleteProduct(String productId);

  /// Increment view count
  Future<Either<Failure, void>> incrementViewCount(String productId);

  /// Mark/Unmark product as featured
  Future<Either<Failure, void>> toggleFeatured(String productId);
}

