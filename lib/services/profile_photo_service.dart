import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilePhotoService {
  static const String _photoUrlKey = 'delivery_boy_profile_photo_url';
  static const String _photoTimestampKey = 'profile_photo_timestamp';

  // ✅ Replace with your actual API endpoint
  static const String uploadEndpoint = 'https://yourapi.com/api/upload-profile-photo';

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
      return await _uploadPhoto(image);
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
      return await _uploadPhoto(image);
    } catch (e) {
      debugPrint('Error picking from camera: $e');
      return null;
    }
  }

  /// ✅ Upload photo to server and return URL
  Future<String?> _uploadPhoto(XFile image) async {
    try {
      debugPrint('📤 Uploading photo to server...');

      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(uploadEndpoint));

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add the image file
      var multipartFile = await http.MultipartFile.fromPath(
        'profile_photo', // Field name expected by your backend
        image.path,
        filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      request.files.add(multipartFile);

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final photoUrl = responseData['photo_url'] ?? responseData['url'];

        if (photoUrl != null) {
          // Save URL to SharedPreferences
          await prefs.setString(_photoUrlKey, photoUrl);
          await prefs.setInt(_photoTimestampKey, DateTime.now().millisecondsSinceEpoch);

          debugPrint('✅ Photo uploaded successfully: $photoUrl');
          return photoUrl;
        }
      } else {
        debugPrint('❌ Upload failed: ${response.statusCode}');
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error uploading photo: $e');
      return null;
    }
  }

  /// ✅ Get profile photo URL from SharedPreferences
  Future<String?> getProfilePhotoUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? photoUrl = prefs.getString(_photoUrlKey);
      return photoUrl;
    } catch (e) {
      debugPrint('Error getting photo URL: $e');
      return null;
    }
  }

  /// ✅ Delete profile photo (remove from preferences)
  Future<bool> deleteProfilePhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_photoUrlKey);
      await prefs.remove(_photoTimestampKey);

      debugPrint('🗑️ Profile photo URL removed');
      return true;
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      return false;
    }
  }
}
