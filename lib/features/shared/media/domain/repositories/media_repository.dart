import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/features/shared/media/domain/entities/media_entity.dart';

/// Media repository interface
/// Defines the contract for media operations
abstract class MediaRepository {
  /// Upload an image to storage
  Future<Either<Failure, MediaEntity>> uploadImage({
    required File imageFile,
    required String bucket,
    String? folder,
  });

  /// Upload multiple images
  Future<Either<Failure, List<MediaEntity>>> uploadImages({
    required List<File> imageFiles,
    required String bucket,
    String? folder,
  });

  /// Delete an image from storage
  Future<Either<Failure, void>> deleteImage({
    required String imageUrl,
    required String bucket,
  });

  /// Delete multiple images
  Future<Either<Failure, void>> deleteImages({
    required List<String> imageUrls,
    required String bucket,
  });

  /// Compress image before upload
  Future<Either<Failure, File>> compressImage(File imageFile);

  /// Pick image from gallery
  Future<Either<Failure, File?>> pickImageFromGallery();

  /// Pick image from camera
  Future<Either<Failure, File?>> pickImageFromCamera();

  /// Pick multiple images from gallery
  Future<Either<Failure, List<File>>> pickMultipleImages();
}


