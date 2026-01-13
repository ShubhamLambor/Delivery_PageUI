// lib/screens/profile/profile_controller.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repository/user_repository.dart';
import '../../services/profile_photo_service.dart'; // ✅ Add this

class ProfileController extends ChangeNotifier {
  final UserRepository _repo = UserRepository();
  final ProfilePhotoService _photoService = ProfilePhotoService(); // ✅ Add this

  String name = '';
  String email = '';
  String phone = '';
  String profilePic = '';
  DateTime? registrationDate;

  // Verification status
  bool isEmailVerified = false;
  bool isPhoneVerified = false;
  bool isLoading = false;

  // Getter for the UI
  String? get profilePhotoUrl => profilePic.isNotEmpty ? profilePic : null;

  // Getter for formatted registration date
  String get memberSince {
    if (registrationDate == null) return 'Member since Jan 2024';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Member since ${months[registrationDate!.month - 1]} ${registrationDate!.year}';
  }

  ProfileController() {
    loadUserData();
  }

  // ✅ Updated to load local photo
  Future<void> loadUserData() async {
    isLoading = true;
    notifyListeners();
    print('[PROFILE_CONTROLLER] Loading user data...');

    try {
      // First, try to get user from repository
      final user = await _repo.getUserProfile();
      print('[PROFILE_CONTROLLER] User loaded from repository:');
      print('  Name: ${user.name}');
      print('  Email: ${user.email}');
      print('  Phone: ${user.phone}');

      name = user.name;
      email = user.email;
      phone = user.phone ?? '';
      registrationDate = user.createdAt;
      isEmailVerified = user.isEmailVerified ?? false;
      isPhoneVerified = user.isPhoneVerified ?? false;

      // ✅ Load local profile photo
      final localPhotoPath = await _photoService.getProfilePhotoPath();
      if (localPhotoPath != null) {
        profilePic = localPhotoPath;
        print('[PROFILE_CONTROLLER] ✅ Local photo loaded: $localPhotoPath');
      } else {
        profilePic = user.profilePic; // Fallback to server photo
        print('[PROFILE_CONTROLLER] Using server photo');
      }

    } catch (e) {
      print('[PROFILE_CONTROLLER] ⚠️ Error loading from repository: $e');
      print('[PROFILE_CONTROLLER] Falling back to SharedPreferences...');

      // Fallback: Load directly from SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        name = prefs.getString('userName') ?? '';
        email = prefs.getString('userEmail') ?? '';
        phone = prefs.getString('userPhone') ?? '';

        // ✅ Load local photo
        final localPhotoPath = await _photoService.getProfilePhotoPath();
        profilePic = localPhotoPath ?? prefs.getString('userProfilePic') ?? '';

        print('[PROFILE_CONTROLLER] Loaded from SharedPreferences:');
        print('  Name: $name');
        print('  Email: $email');
        print('  Photo: $profilePic');
      } catch (prefError) {
        print('[PROFILE_CONTROLLER] ❌ Failed to load from SharedPreferences: $prefError');
      }
    }

    isLoading = false;
    notifyListeners();
    print('[PROFILE_CONTROLLER] ✅ Load complete - Current name: $name');
  }

  Future<void> refreshUserData() async {
    await loadUserData();
  }

  Future<void> logout() async {
    _repo.logout();
  }

  Future<void> updateName(String newName) async {
    _repo.updateUserName(newName);
    name = newName;
    notifyListeners();
  }

  Future<void> updateProfilePic(String urlOrPath) async {
    _repo.updateProfilePic(urlOrPath);
    profilePic = urlOrPath;
    notifyListeners();
  }

  Future<void> updateEmail(String newEmail) async {
    await _repo.updateEmail(newEmail);
    email = newEmail;
    isEmailVerified = false;
    notifyListeners();
  }

  Future<void> updatePhone(String newPhone) async {
    await _repo.updatePhone(newPhone);
    phone = newPhone;
    isPhoneVerified = false;
    notifyListeners();
  }

  void markEmailVerified() {
    isEmailVerified = true;
    notifyListeners();
  }

  void markPhoneVerified() {
    isPhoneVerified = true;
    notifyListeners();
  }

  // ✅ Updated changeProfilePhoto method
  Future<void> changeProfilePhoto(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Choose Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Camera option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.blue),
                ),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),

              // Gallery option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.green),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),

              // Delete option (if photo exists)
              if (profilePic.isNotEmpty)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: const Text('Remove Photo'),
                  onTap: () => Navigator.pop(ctx, null),
                ),
            ],
          ),
        ),
      ),
    );

    if (source == null && profilePic.isNotEmpty) {
      // User wants to delete photo
      await _photoService.deleteProfilePhoto();
      profilePic = '';
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo removed')),
        );
      }
      return;
    }

    if (source == null) return;

    // Pick and save photo
    String? newPath;
    if (source == ImageSource.camera) {
      newPath = await _photoService.pickFromCamera();
    } else {
      newPath = await _photoService.pickFromGallery();
    }

    if (newPath != null) {
      await updateProfilePic(newPath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile photo updated!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
