import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/media/domain/entities/media_entity.dart';
import 'package:mwanachuo/features/shared/media/domain/repositories/media_repository.dart';

/// Use case for uploading a video file (bypasses image compression)
class UploadVideo implements UseCase<MediaEntity, UploadVideoParams> {
  final MediaRepository repository;

  UploadVideo(this.repository);

  @override
  Future<Either<Failure, MediaEntity>> call(UploadVideoParams params) async {
    // For videos, we skip compression and upload directly
    return await repository.uploadImage(
      imageFile: params.videoFile,
      bucket: params.bucket,
      folder: params.folder,
    );
  }
}

class UploadVideoParams extends Equatable {
  final File videoFile;
  final String bucket;
  final String? folder;

  const UploadVideoParams({
    required this.videoFile,
    required this.bucket,
    this.folder,
  });

  @override
  List<Object?> get props => [videoFile, bucket, folder];
}
