import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:mwanachuo/features/shared/media/domain/entities/media_entity.dart';

/// Base class for all media states
abstract class MediaState extends Equatable {
  const MediaState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class MediaInitial extends MediaState {}

/// Picking image
class MediaPicking extends MediaState {}

/// Image(s) picked
class MediaPicked extends MediaState {
  final List<File> files;

  const MediaPicked({required this.files});

  @override
  List<Object?> get props => [files];
}

/// Uploading image(s)
class MediaUploading extends MediaState {
  final double progress;

  const MediaUploading({this.progress = 0.0});

  @override
  List<Object?> get props => [progress];
}

/// Upload successful
class MediaUploadSuccess extends MediaState {
  final List<MediaEntity> uploadedMedia;

  const MediaUploadSuccess({required this.uploadedMedia});

  @override
  List<Object?> get props => [uploadedMedia];
}

/// Deleting image(s)
class MediaDeleting extends MediaState {}

/// Delete successful
class MediaDeleteSuccess extends MediaState {}

/// Error state
class MediaError extends MediaState {
  final String message;

  const MediaError({required this.message});

  @override
  List<Object?> get props => [message];
}


