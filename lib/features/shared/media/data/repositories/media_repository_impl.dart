import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/network/network_info.dart';
import 'package:mwanachuo/features/shared/media/data/datasources/media_local_data_source.dart';
import 'package:mwanachuo/features/shared/media/data/datasources/media_remote_data_source.dart';
import 'package:mwanachuo/features/shared/media/domain/entities/media_entity.dart';
import 'package:mwanachuo/features/shared/media/domain/repositories/media_repository.dart';

/// Implementation of MediaRepository
class MediaRepositoryImpl implements MediaRepository {
  final MediaRemoteDataSource remoteDataSource;
  final MediaLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  MediaRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, MediaEntity>> uploadImage({
    required File imageFile,
    required String bucket,
    String? folder,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final media = await remoteDataSource.uploadImage(
        imageFile: imageFile,
        bucket: bucket,
        folder: folder,
      );
      return Right(media);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to upload image: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MediaEntity>>> uploadImages({
    required List<File> imageFiles,
    required String bucket,
    String? folder,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      final media = await remoteDataSource.uploadImages(
        imageFiles: imageFiles,
        bucket: bucket,
        folder: folder,
      );
      return Right(media);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to upload images: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteImage({
    required String imageUrl,
    required String bucket,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.deleteImage(
        imageUrl: imageUrl,
        bucket: bucket,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to delete image: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteImages({
    required List<String> imageUrls,
    required String bucket,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('No internet connection'));
    }

    try {
      await remoteDataSource.deleteImages(
        imageUrls: imageUrls,
        bucket: bucket,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to delete images: $e'));
    }
  }

  @override
  Future<Either<Failure, File>> compressImage(File imageFile) async {
    try {
      final compressedFile = await localDataSource.compressImage(imageFile);
      return Right(compressedFile);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      // If compression fails, return original file
      return Right(imageFile);
    }
  }

  @override
  Future<Either<Failure, File?>> pickImageFromGallery() async {
    try {
      final file = await localDataSource.pickImageFromGallery();
      return Right(file);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to pick image: $e'));
    }
  }

  @override
  Future<Either<Failure, File?>> pickImageFromCamera() async {
    try {
      final file = await localDataSource.pickImageFromCamera();
      return Right(file);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to pick image: $e'));
    }
  }

  @override
  Future<Either<Failure, List<File>>> pickMultipleImages() async {
    try {
      final files = await localDataSource.pickMultipleImages();
      return Right(files);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to pick images: $e'));
    }
  }
}


