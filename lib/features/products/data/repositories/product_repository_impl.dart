import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/constants/database_constants.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/network/network_info.dart';
import 'package:mwanachuo/core/services/logger_service.dart';
import 'package:mwanachuo/features/products/data/datasources/product_local_data_source.dart';
import 'package:mwanachuo/features/products/data/datasources/product_remote_data_source.dart';
import 'package:mwanachuo/features/products/domain/entities/product_entity.dart';
import 'package:mwanachuo/features/products/domain/repositories/product_repository.dart';
import 'package:mwanachuo/features/shared/media/domain/usecases/upload_multiple_images.dart';

/// Implementation of ProductRepository
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final UploadMultipleImages uploadImages;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.uploadImages,
  });

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    String? category,
    String? universityId,
    String? sellerId,
    bool? isFeatured,
    int? limit,
    int? offset,
  }) async {
    if (!await networkInfo.isConnected) {
      // Try to get from cache
      try {
        final cachedProducts = await localDataSource.getCachedProducts();
        return Right(cachedProducts);
      } on CacheException {
        return Left(
          NetworkFailure('No internet connection and no cached data'),
        );
      }
    }

    try {
      final products = await remoteDataSource.getProducts(
        category: category,
        universityId: universityId,
        sellerId: sellerId,
        isFeatured: isFeatured,
        limit: limit,
        offset: offset,
      );

      // Cache products
      await localDataSource.cacheProducts(products);

      return Right(products);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get products: $e'));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> getProductById(
    String productId,
  ) async {
    if (!await networkInfo.isConnected) {
      // Try to get from cache
      try {
        final cachedProduct = await localDataSource.getCachedProduct(productId);
        return Right(cachedProduct);
      } on CacheException {
        return Left(
          NetworkFailure('No internet connection and no cached data'),
        );
      }
    }

    try {
      final product = await remoteDataSource.getProductById(productId);

      // Cache product
      await localDataSource.cacheProduct(product);

      return Right(product);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get product: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getMyProducts({
    int? limit,
    int? offset,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final products = await remoteDataSource.getMyProducts(
        limit: limit,
        offset: offset,
      );
      return Right(products);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get my products: $e'));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> createProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    required List<File> images,
    required String location,
    Map<String, dynamic>? metadata,
  }) async {
      LoggerService.info('ProductRepository: Creating product - $title');
      
      if (!await networkInfo.isConnected) {
        LoggerService.warning('ProductRepository: No internet connection');
        return Left(NetworkFailure('No internet connection'));
      }

      try {
        // Upload images first
        LoggerService.info('ProductRepository: Uploading ${images.length} images...');
        final uploadResult = await uploadImages(
          UploadMultipleImagesParams(
            imageFiles: images,
            bucket: DatabaseConstants.productImagesBucket,
            folder: 'products',
          ),
        );

        return await uploadResult.fold(
          (failure) {
            LoggerService.error('ProductRepository: Image upload failed', failure.message);
            return Left(failure);
          },
          (uploadedMedia) async {
            final imageUrls = uploadedMedia.map((m) => m.url).toList();
            LoggerService.info('ProductRepository: Images uploaded successfully - ${imageUrls.length} URLs');

            LoggerService.info('ProductRepository: Creating product in database...');
            final product = await remoteDataSource.createProduct(
              title: title,
              description: description,
              price: price,
              category: category,
              condition: condition,
              imageUrls: imageUrls,
              location: location,
              metadata: metadata,
            );

            LoggerService.info('ProductRepository: Product created - ID: ${product.id}');

            // Add product to cache (incremental update)
            try {
              await localDataSource.addProductToCache(product);
              LoggerService.debug('ProductRepository: Product added to cache');
            } catch (e) {
              LoggerService.warning('ProductRepository: Failed to cache product', e);
              // Non-critical error, continue
            }

            return Right(product);
          },
        );
      } on ServerException catch (e) {
        LoggerService.error('ProductRepository: ServerException', e.message);
        return Left(ServerFailure(e.message));
      } catch (e, stackTrace) {
        LoggerService.error('ProductRepository: Unexpected error', e, stackTrace);
        return Left(ServerFailure('Failed to create product: $e'));
      }
  }

  @override
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
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      List<String>? finalImageUrls;

      // Upload new images if provided
      if (newImages != null && newImages.isNotEmpty) {
        final uploadResult = await uploadImages(
          UploadMultipleImagesParams(
            imageFiles: newImages,
            bucket: DatabaseConstants.productImagesBucket,
            folder: 'products',
          ),
        );

        final newImageUrls = uploadResult.fold(
          (failure) => <String>[],
          (uploadedMedia) => uploadedMedia.map((m) => m.url).toList(),
        );

        // Combine existing and new images
        finalImageUrls = [
          ...(existingImages ?? []),
          ...newImageUrls,
        ];
      } else if (existingImages != null) {
        finalImageUrls = existingImages;
      }

      final product = await remoteDataSource.updateProduct(
        productId: productId,
        title: title,
        description: description,
        price: price,
        category: category,
        condition: condition,
        imageUrls: finalImageUrls,
        location: location,
        isActive: isActive,
        metadata: metadata,
      );

      // Update product in cache (incremental update)
      try {
        await localDataSource.updateProductInCache(product);
        debugPrint('✅ ProductRepository: Product updated in cache');
      } catch (e) {
        debugPrint('⚠️  ProductRepository: Failed to update cache - $e');
        // Non-critical error, continue
      }

      return Right(product);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to update product: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String productId) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.deleteProduct(productId);

      // Clear cache
      await localDataSource.clearCache();

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to delete product: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> incrementViewCount(String productId) async {
    if (!await networkInfo.isConnected) {
      return const Right(null); // Silently fail if offline
    }

    try {
      await remoteDataSource.incrementViewCount(productId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to increment view count: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleFeatured(String productId) async {
    // This would typically be an admin function
    // For now, return not implemented
    return Left(ServerFailure('Feature not implemented'));
  }
}

