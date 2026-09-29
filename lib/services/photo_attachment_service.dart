import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Service for capturing and managing on-site survey photos (doors, room entrances, amenities, signage).
class PhotoAttachmentService {
  static final ImagePicker _picker = ImagePicker();

  /// Captures a photo using device camera or picks from device gallery
  static Future<String?> captureOrPickPhoto({
    ImageSource source = ImageSource.camera,
    int imageQuality = 85,
    double? maxWidth = 1920,
    double? maxHeight = 1080,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (file == null) return null;

      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory photosDir = Directory(p.join(appDir.path, 'survey_photos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = p.extension(file.path).isNotEmpty ? p.extension(file.path) : '.jpg';
      final String savedPath = p.join(photosDir.path, 'survey_img_$timestamp$extension');

      final File savedFile = await File(file.path).copy(savedPath);
      return savedFile.path;
    } catch (e) {
      debugPrint('PhotoAttachmentService error: $e');
      return null;
    }
  }

  /// Deletes a locally stored survey photo
  static Future<bool> deletePhoto(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      return false;
    }
  }
}
