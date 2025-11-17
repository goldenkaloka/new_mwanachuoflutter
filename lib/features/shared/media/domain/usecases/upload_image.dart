import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/media/domain/entities/media_entity.dart';
import 'package:mwanachuo/features/shared/media/domain/repositories/media_repository.dart';

/// Use case for uploading a single image
class UploadImage implements UseCase<MediaEntity, UploadImageParams> {
  final MediaRepository repository;

  UploadImage(this.repository);

  @override
  Future<Either<Failure, MediaEntity>> call(UploadImageParams params) async {
    // Compress image first
    final compressionResult = await repository.compressImage(params.imageFile);

    return await compressionResult.fold(
      (failure) => Left(failure),
      (compressedFile) async {
        return await repository.uploadImage(
          imageFile: compressedFile,
          bucket: params.bucket,
          folder: params.folder,
        );
      },
    );
  }
}

class UploadImageParams extends Equatable {
  final File imageFile;
  final String bucket;
  final String? folder;

  const UploadImageParams({
    required this.imageFile,
    required this.bucket,
    this.folder,
  });

  @override
  List<Object?> get props => [imageFile, bucket, folder];
}


