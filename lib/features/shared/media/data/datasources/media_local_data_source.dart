import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mwanachuo/core/errors/exceptions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Abstract class defining media local data source operations
abstract class MediaLocalDataSource {
  /// Compress image
  Future<File> compressImage(File imageFile);

  /// Pick image from gallery
  Future<File?> pickImageFromGallery();

  /// Pick image from camera
  Future<File?> pickImageFromCamera();

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleImages();
}

/// Implementation of MediaLocalDataSource
class MediaLocalDataSourceImpl implements MediaLocalDataSource {
  final ImagePicker imagePicker;

  MediaLocalDataSourceImpl({ImagePicker? imagePicker})
      : imagePicker = imagePicker ?? ImagePicker();

  @override
  Future<File> compressImage(File imageFile) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        '${DateTime.now().millisecondsSinceEpoch}_compressed${path.extension(imageFile.path)}',
      );

      // Compress image
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 85,
        minWidth: 1920,
        minHeight: 1080,
      );

      if (compressedFile == null) {
        // If compression fails, return original file
        return imageFile;
      }

      return File(compressedFile.path);
    } catch (e) {
      // If compression fails, return original file
      return imageFile;
    }
  }

  @override
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return null;
      }

      return File(pickedFile.path);
    } catch (e) {
      throw CacheException('Failed to pick image from gallery: $e');
    }
  }

  @override
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return null;
      }

      return File(pickedFile.path);
    } catch (e) {
      throw CacheException('Failed to pick image from camera: $e');
    }
  }

  @override
  Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> pickedFiles = await imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return pickedFiles.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      throw CacheException('Failed to pick multiple images: $e');
    }
  }
}


