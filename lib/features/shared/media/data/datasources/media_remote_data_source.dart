import 'dart:io';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:mwanachuo/core/services/logger_service.dart';
import 'package:mwanachuo/features/shared/media/data/models/media_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// Abstract class defining media remote data source operations
abstract class MediaRemoteDataSource {
  /// Upload image to Supabase Storage
  Future<MediaModel> uploadImage({
    required File imageFile,
    required String bucket,
    String? folder,
  });

  /// Upload multiple images
  Future<List<MediaModel>> uploadImages({
    required List<File> imageFiles,
    required String bucket,
    String? folder,
  });

  /// Delete image from Supabase Storage
  Future<void> deleteImage({
    required String imageUrl,
    required String bucket,
  });

  /// Delete multiple images
  Future<void> deleteImages({
    required List<String> imageUrls,
    required String bucket,
  });
}

/// Implementation of MediaRemoteDataSource using Supabase
class MediaRemoteDataSourceImpl implements MediaRemoteDataSource {
  final SupabaseClient supabaseClient;
  final Uuid uuid;
  final int maxRetries;
  final Duration initialRetryDelay;

  MediaRemoteDataSourceImpl({
    required this.supabaseClient,
    Uuid? uuid,
    this.maxRetries = 3,
    this.initialRetryDelay = const Duration(seconds: 1),
  }) : uuid = uuid ?? const Uuid();

  @override
  Future<MediaModel> uploadImage({
    required File imageFile,
    required String bucket,
    String? folder,
  }) async {
    return await _uploadWithRetry(
      imageFile: imageFile,
      bucket: bucket,
      folder: folder,
    );
  }

  /// Upload image with retry logic and exponential backoff
  Future<MediaModel> _uploadWithRetry({
    required File imageFile,
    required String bucket,
    String? folder,
    int attempt = 1,
  }) async {
    try {
      LoggerService.debug('Upload attempt $attempt/$maxRetries - bucket: $bucket, folder: $folder');
      
      // Generate unique file name
      final extension = path.extension(imageFile.path);
      final fileName = '${uuid.v4()}$extension';
      final filePath = folder != null ? '$folder/$fileName' : fileName;
      
      LoggerService.debug('File path: $filePath, extension: $extension');

      // Get file info
      final fileBytes = await imageFile.readAsBytes();
      final fileSize = fileBytes.length;
      
      LoggerService.debug('File size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      // Upload to Supabase Storage
      LoggerService.info('Uploading to Supabase Storage...');
      await supabaseClient.storage.from(bucket).uploadBinary(
            filePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: _getContentType(extension),
              upsert: false,
            ),
          );

      LoggerService.info('Upload successful on attempt $attempt!');

      // Get public URL
      final publicUrl = supabaseClient.storage.from(bucket).getPublicUrl(filePath);
      
      LoggerService.debug('Public URL generated: $publicUrl');

      return MediaModel.fromSupabaseUpload(
        id: fileName,
        publicUrl: publicUrl,
        fileName: fileName,
        fileType: extension,
        fileSize: fileSize,
      );
    } on StorageException catch (e) {
      // Retry on network errors
      if (attempt < maxRetries && _isRetryableError(e)) {
        final delay = initialRetryDelay * (1 << (attempt - 1)); // Exponential backoff
        LoggerService.warning('Upload failed (${e.message}), retrying in ${delay.inSeconds}s... (attempt $attempt/$maxRetries)');
        await Future.delayed(delay);
        return _uploadWithRetry(
          imageFile: imageFile,
          bucket: bucket,
          folder: folder,
          attempt: attempt + 1,
        );
      }
      LoggerService.error('StorageException after $attempt attempts', e.message);
      throw ServerException('Storage error: ${e.message} (${e.statusCode})');
    } catch (e, stackTrace) {
      // Retry on network errors
      if (attempt < maxRetries && _isNetworkError(e)) {
        final delay = initialRetryDelay * (1 << (attempt - 1)); // Exponential backoff
        LoggerService.warning('Network error, retrying in ${delay.inSeconds}s... (attempt $attempt/$maxRetries)');
        await Future.delayed(delay);
        return _uploadWithRetry(
          imageFile: imageFile,
          bucket: bucket,
          folder: folder,
          attempt: attempt + 1,
        );
      }
      LoggerService.error('Upload failed after $attempt attempts', e, stackTrace);
      throw ServerException('Failed to upload image: $e');
    }
  }

  /// Check if error is retryable
  bool _isRetryableError(StorageException e) {
    // Retry on network/timeout errors, not on auth/validation errors
    return e.statusCode == null || 
           e.statusCode == '408' || // Request Timeout
           e.statusCode == '429' || // Too Many Requests
           e.statusCode == '500' || // Internal Server Error
           e.statusCode == '502' || // Bad Gateway
           e.statusCode == '503' || // Service Unavailable
           e.statusCode == '504';   // Gateway Timeout
  }

  /// Check if error is a network error
  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('socket');
  }

  @override
  Future<List<MediaModel>> uploadImages({
    required List<File> imageFiles,
    required String bucket,
    String? folder,
  }) async {
    final List<MediaModel> uploadedImages = [];
    final List<String> errors = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final uploaded = await uploadImage(
          imageFile: imageFiles[i],
          bucket: bucket,
          folder: folder,
        );
        uploadedImages.add(uploaded);
        debugPrint('✅ Successfully uploaded image ${i + 1}/${imageFiles.length}');
      } catch (e) {
        // Collect error details
        final errorMessage = 'Image ${i + 1}: $e';
        errors.add(errorMessage);
        debugPrint('❌ Failed to upload image ${i + 1}/${imageFiles.length}: $e');
        // Continue uploading other images even if one fails
        continue;
      }
    }

    if (uploadedImages.isEmpty && imageFiles.isNotEmpty) {
      final detailedError = 'Failed to upload any images. Errors: ${errors.join(', ')}';
      debugPrint('❌ Upload failed: $detailedError');
      throw ServerException(detailedError);
    }

    debugPrint('✅ Upload complete: ${uploadedImages.length}/${imageFiles.length} images uploaded successfully');
    return uploadedImages;
  }

  @override
  Future<void> deleteImage({
    required String imageUrl,
    required String bucket,
  }) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final filePath = pathSegments.sublist(pathSegments.indexOf(bucket) + 1).join('/');

      await supabaseClient.storage.from(bucket).remove([filePath]);
    } on StorageException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to delete image: $e');
    }
  }

  @override
  Future<void> deleteImages({
    required List<String> imageUrls,
    required String bucket,
  }) async {
    try {
      final List<String> filePaths = [];

      for (final imageUrl in imageUrls) {
        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;
        final filePath = pathSegments.sublist(pathSegments.indexOf(bucket) + 1).join('/');
        filePaths.add(filePath);
      }

      await supabaseClient.storage.from(bucket).remove(filePaths);
    } on StorageException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException('Failed to delete images: $e');
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}


