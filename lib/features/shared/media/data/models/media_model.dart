import 'package:mwanachuo/features/shared/media/domain/entities/media_entity.dart';

/// Media model for the data layer
class MediaModel extends MediaEntity {
  const MediaModel({
    required super.id,
    required super.url,
    required super.fileName,
    required super.fileType,
    required super.fileSize,
    required super.uploadedAt,
    super.thumbnailUrl,
  });

  /// Create a MediaModel from JSON
  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id'] as String,
      url: json['url'] as String,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }

  /// Convert MediaModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'uploaded_at': uploadedAt.toIso8601String(),
      'thumbnail_url': thumbnailUrl,
    };
  }

  /// Create a MediaModel from Supabase storage response
  factory MediaModel.fromSupabaseUpload({
    required String id,
    required String publicUrl,
    required String fileName,
    required String fileType,
    required int fileSize,
  }) {
    return MediaModel(
      id: id,
      url: publicUrl,
      fileName: fileName,
      fileType: fileType,
      fileSize: fileSize,
      uploadedAt: DateTime.now(),
    );
  }
}


