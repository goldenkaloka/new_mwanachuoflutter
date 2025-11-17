import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/media/domain/repositories/media_repository.dart';

/// Use case for picking an image
class PickImage implements UseCase<File?, PickImageParams> {
  final MediaRepository repository;

  PickImage(this.repository);

  @override
  Future<Either<Failure, File?>> call(PickImageParams params) async {
    if (params.fromCamera) {
      return await repository.pickImageFromCamera();
    } else {
      return await repository.pickImageFromGallery();
    }
  }
}

class PickImageParams extends Equatable {
  final bool fromCamera;

  const PickImageParams({this.fromCamera = false});

  @override
  List<Object?> get props => [fromCamera];
}


