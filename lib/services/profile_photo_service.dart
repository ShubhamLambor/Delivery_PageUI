import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

class ProfilePhotoService {
  static const String _photoPathKey = 'delivery_boy_profile_photo_path';
  static const String _photoTimestampKey = 'profile_photo_timestamp';

  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<String?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;
      return await _savePhoto(image);
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      return null;
    }
  }

  /// Pick image from camera
  Future<String?> pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image == null) return null;
      return await _savePhoto(image);
    } catch (e) {
      debugPrint('Error picking from camera: $e');
      return null;
    }
  }

  /// Save photo to local storage
  Future<String?> _savePhoto(XFile image) async {
    try {
      // Delete old photo if exists
      await deleteProfilePhoto();

      // Get app directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String localPath = path.join(appDir.path, 'profile_photos', fileName);

      // Create directory if doesn't exist
      final Directory profileDir = Directory(path.join(appDir.path, 'profile_photos'));
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }

      // Compress and save image
      final File imageFile = File(image.path);
      final img.Image? originalImage = img.decodeImage(await imageFile.readAsBytes());

      if (originalImage != null) {
        // Resize if needed
        final img.Image resized = img.copyResize(
          originalImage,
          width: originalImage.width > 800 ? 800 : originalImage.width,
        );

        // Save compressed image
        final File compressedFile = File(localPath);
        await compressedFile.writeAsBytes(img.encodeJpg(resized, quality: 85));

        // Save path and timestamp to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_photoPathKey, localPath);
        await prefs.setInt(_photoTimestampKey, DateTime.now().millisecondsSinceEpoch);

        debugPrint('✅ Profile photo saved: $localPath');
        return localPath;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error saving photo: $e');
      return null;
    }
  }

  /// Get profile photo path
  Future<String?> getProfilePhotoPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? photoPath = prefs.getString(_photoPathKey);

      // Check if file exists
      if (photoPath != null && await File(photoPath).exists()) {
        return photoPath;
      } else if (photoPath != null) {
        // Path exists but file doesn't - clean up
        await prefs.remove(_photoPathKey);
        await prefs.remove(_photoTimestampKey);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting photo path: $e');
      return null;
    }
  }

  /// Delete profile photo
  Future<bool> deleteProfilePhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? photoPath = prefs.getString(_photoPathKey);

      if (photoPath != null) {
        final File photoFile = File(photoPath);
        if (await photoFile.exists()) {
          await photoFile.delete();
          debugPrint('🗑️ Deleted old profile photo');
        }

        await prefs.remove(_photoPathKey);
        await prefs.remove(_photoTimestampKey);
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      return false;
    }
  }
}
