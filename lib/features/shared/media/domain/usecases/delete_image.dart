import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/media/domain/repositories/media_repository.dart';

/// Use case for deleting an image
class DeleteImage implements UseCase<void, DeleteImageParams> {
  final MediaRepository repository;

  DeleteImage(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteImageParams params) async {
    return await repository.deleteImage(
      imageUrl: params.imageUrl,
      bucket: params.bucket,
    );
  }
}

class DeleteImageParams extends Equatable {
  final String imageUrl;
  final String bucket;

  const DeleteImageParams({
    required this.imageUrl,
    required this.bucket,
  });

  @override
  List<Object?> get props => [imageUrl, bucket];
}


