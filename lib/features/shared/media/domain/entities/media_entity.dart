import 'package:equatable/equatable.dart';

/// Media entity representing an uploaded media file
class MediaEntity extends Equatable {
  final String id;
  final String url;
  final String fileName;
  final String fileType;
  final int fileSize;
  final DateTime uploadedAt;
  final String? thumbnailUrl;

  const MediaEntity({
    required this.id,
    required this.url,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
    this.thumbnailUrl,
  });

  @override
  List<Object?> get props => [
        id,
        url,
        fileName,
        fileType,
        fileSize,
        uploadedAt,
        thumbnailUrl,
      ];
}


