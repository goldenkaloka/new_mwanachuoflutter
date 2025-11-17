import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwanachuo/core/usecases/usecase.dart';
import 'package:mwanachuo/features/shared/media/domain/usecases/delete_image.dart';
import 'package:mwanachuo/features/shared/media/domain/usecases/pick_image.dart';
import 'package:mwanachuo/features/shared/media/domain/usecases/pick_multiple_images.dart';
import 'package:mwanachuo/features/shared/media/domain/usecases/upload_image.dart';
import 'package:mwanachuo/features/shared/media/domain/usecases/upload_multiple_images.dart';
import 'package:mwanachuo/features/shared/media/presentation/cubit/media_state.dart';

/// Cubit for managing media state
class MediaCubit extends Cubit<MediaState> {
  final PickImage pickImage;
  final PickMultipleImages pickMultipleImages;
  final UploadImage uploadImage;
  final UploadMultipleImages uploadMultipleImages;
  final DeleteImage deleteImage;

  MediaCubit({
    required this.pickImage,
    required this.pickMultipleImages,
    required this.uploadImage,
    required this.uploadMultipleImages,
    required this.deleteImage,
  }) : super(MediaInitial());

  /// Pick single image from gallery
  Future<void> pickFromGallery() async {
    emit(MediaPicking());

    final result = await pickImage(const PickImageParams(fromCamera: false));

    result.fold(
      (failure) => emit(MediaError(message: failure.message)),
      (file) {
        if (file != null) {
          emit(MediaPicked(files: [file]));
        } else {
          emit(MediaInitial());
        }
      },
    );
  }

  /// Pick single image from camera
  Future<void> pickFromCamera() async {
    emit(MediaPicking());

    final result = await pickImage(const PickImageParams(fromCamera: true));

    result.fold(
      (failure) => emit(MediaError(message: failure.message)),
      (file) {
        if (file != null) {
          emit(MediaPicked(files: [file]));
        } else {
          emit(MediaInitial());
        }
      },
    );
  }

  /// Pick multiple images from gallery
  Future<void> pickMultiple() async {
    emit(MediaPicking());

    final result = await pickMultipleImages(NoParams());

    result.fold(
      (failure) => emit(MediaError(message: failure.message)),
      (files) {
        if (files.isNotEmpty) {
          emit(MediaPicked(files: files));
        } else {
          emit(MediaInitial());
        }
      },
    );
  }

  /// Upload single image
  Future<void> uploadSingleImage({
    required File imageFile,
    required String bucket,
    String? folder,
  }) async {
    emit(const MediaUploading(progress: 0.0));

    final result = await uploadImage(
      UploadImageParams(
        imageFile: imageFile,
        bucket: bucket,
        folder: folder,
      ),
    );

    result.fold(
      (failure) => emit(MediaError(message: failure.message)),
      (media) => emit(MediaUploadSuccess(uploadedMedia: [media])),
    );
  }

  /// Upload multiple images
  Future<void> uploadMultiple({
    required List<File> imageFiles,
    required String bucket,
    String? folder,
  }) async {
    emit(const MediaUploading(progress: 0.0));

    final result = await uploadMultipleImages(
      UploadMultipleImagesParams(
        imageFiles: imageFiles,
        bucket: bucket,
        folder: folder,
      ),
    );

    result.fold(
      (failure) => emit(MediaError(message: failure.message)),
      (media) => emit(MediaUploadSuccess(uploadedMedia: media)),
    );
  }

  /// Delete single image
  Future<void> deleteSingleImage({
    required String imageUrl,
    required String bucket,
  }) async {
    emit(MediaDeleting());

    final result = await deleteImage(
      DeleteImageParams(
        imageUrl: imageUrl,
        bucket: bucket,
      ),
    );

    result.fold(
      (failure) => emit(MediaError(message: failure.message)),
      (_) => emit(MediaDeleteSuccess()),
    );
  }

  /// Reset to initial state
  void reset() {
    emit(MediaInitial());
  }
}


