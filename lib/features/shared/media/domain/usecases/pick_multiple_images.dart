import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:mwanachuo/core/errors/failures.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/media/domain/repositories/media_repository.dart';

/// Use case for picking multiple images
class PickMultipleImages implements UseCase<List<File>, NoParams> {
  final MediaRepository repository;

  PickMultipleImages(this.repository);

  @override
  Future<Either<Failure, List<File>>> call(NoParams params) async {
    return await repository.pickMultipleImages();
  }
}


