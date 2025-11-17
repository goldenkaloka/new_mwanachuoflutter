import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/media/domain/entities/media_entity.dart';
import 'package:mwanachuo/features/shared/media/domain/repositories/media_repository.dart';

/// Use case for uploading multiple images
class UploadMultipleImages
    implements UseCase<List<MediaEntity>, UploadMultipleImagesParams> {
  final MediaRepository repository;

  UploadMultipleImages(this.repository);

  @override
  Future<Either<Failure, List<MediaEntity>>> call(
    UploadMultipleImagesParams params,
  ) async {
    // Compress all images first
    final List<File> compressedFiles = [];

    for (final imageFile in params.imageFiles) {
      final compressionResult = await repository.compressImage(imageFile);
      final compressed = compressionResult.fold(
        (failure) => imageFile, // Use original if compression fails
        (compressedFile) => compressedFile,
      );
      compressedFiles.add(compressed);
    }

    return await repository.uploadImages(
      imageFiles: compressedFiles,
      bucket: params.bucket,
      folder: params.folder,
    );
  }
}

class UploadMultipleImagesParams extends Equatable {
  final List<File> imageFiles;
  final String bucket;
  final String? folder;

  const UploadMultipleImagesParams({
    required this.imageFiles,
    required this.bucket,
    this.folder,
  });

  @override
  List<Object?> get props => [imageFiles, bucket, folder];
}


