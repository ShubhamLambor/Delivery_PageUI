// lib/screens/profile/profile_controller.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repository/user_repository.dart';
import '../../services/profile_photo_service.dart';

class ProfileController extends ChangeNotifier {
  final UserRepository _repo = UserRepository();
  final ProfilePhotoService _photoService = ProfilePhotoService();

  String name = '';
  String email = '';
  String phone = '';
  String profilePic = ''; // ✅ Now stores network URL
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

  // ✅ Updated to load network photo URL
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

      // ✅ Load network photo URL from local cache first, then server
      final cachedPhotoUrl = await _photoService.getProfilePhotoUrl();
      if (cachedPhotoUrl != null && cachedPhotoUrl.isNotEmpty) {
        profilePic = cachedPhotoUrl;
        print('[PROFILE_CONTROLLER] ✅ Cached photo URL loaded: $cachedPhotoUrl');
      } else {
        profilePic = user.profilePic; // Fallback to server photo
        print('[PROFILE_CONTROLLER] Using server photo URL: ${user.profilePic}');
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

        // ✅ Load photo URL from cache
        final cachedPhotoUrl = await _photoService.getProfilePhotoUrl();
        profilePic = cachedPhotoUrl ?? prefs.getString('userProfilePic') ?? '';

        print('[PROFILE_CONTROLLER] Loaded from SharedPreferences:');
        print('  Name: $name');
        print('  Email: $email');
        print('  Photo URL: $profilePic');
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

  // ✅ Updated to handle network URLs
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

  // ✅ FIXED: Updated changeProfilePhoto method - NO OVERFLOW
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

    // ✅ Handle photo removal
    if (source == null && profilePic.isNotEmpty) {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove Photo'),
          content: const Text('Are you sure you want to remove your profile photo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _photoService.deleteProfilePhoto();
        profilePic = '';
        notifyListeners();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profile photo removed'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      return;
    }

    if (source == null) return;

    // ✅ FIXED: Show loading dialog with proper constraints
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 40), // ✅ Add margin
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Uploading photo...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center, // ✅ Center align
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ✅ Pick and upload photo to server
    String? newPhotoUrl;
    try {
      if (source == ImageSource.camera) {
        newPhotoUrl = await _photoService.pickFromCamera();
      } else {
        newPhotoUrl = await _photoService.pickFromGallery();
      }
    } catch (e) {
      print('[PROFILE_CONTROLLER] Error picking/uploading photo: $e');
    }

    // ✅ Close loading dialog
    if (context.mounted) {
      Navigator.pop(context);
    }

    // ✅ FIXED: Handle result with Flexible widget
    if (newPhotoUrl != null && newPhotoUrl.isNotEmpty) {
      await updateProfilePic(newPhotoUrl);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Flexible( // ✅ Wrap in Flexible to prevent overflow
                  child: Text(
                    'Profile photo updated successfully!',
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis, // ✅ Handle long text
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // ✅ FIXED: Show error message with Flexible
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Flexible( // ✅ Wrap in Flexible to prevent overflow
                  child: Text(
                    'Failed to upload photo. Please try again.',
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis, // ✅ Handle long text
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => changeProfilePhoto(context),
            ),
          ),
        );
      }
    }
  }
}
