// lib/screens/profile/profile_controller.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Add this
import '../../data/repository/user_repository.dart';

class ProfileController extends ChangeNotifier {
  final UserRepository _repo = UserRepository();
  final ImagePicker _picker = ImagePicker();

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

  // ✅ Updated to fetch fresh data from SharedPreferences
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
      profilePic = user.profilePic;
      registrationDate = user.createdAt;
      isEmailVerified = user.isEmailVerified ?? false;
      isPhoneVerified = user.isPhoneVerified ?? false;

    } catch (e) {
      print('[PROFILE_CONTROLLER] ⚠️ Error loading from repository: $e');
      print('[PROFILE_CONTROLLER] Falling back to SharedPreferences...');

      // Fallback: Load directly from SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        name = prefs.getString('userName') ?? '';
        email = prefs.getString('userEmail') ?? '';
        phone = prefs.getString('userPhone') ?? '';
        profilePic = prefs.getString('userProfilePic') ?? '';

        print('[PROFILE_CONTROLLER] Loaded from SharedPreferences:');
        print('  Name: $name');
        print('  Email: $email');

      } catch (prefError) {
        print('[PROFILE_CONTROLLER] ❌ Failed to load from SharedPreferences: $prefError');
      }
    }

    isLoading = false;
    notifyListeners();

    print('[PROFILE_CONTROLLER] ✅ Load complete - Current name: $name');
  }

  // ✅ Add this method to refresh data when profile page is opened
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

  // Update email and phone
  Future<void> updateEmail(String newEmail) async {
    await _repo.updateEmail(newEmail);
    email = newEmail;
    isEmailVerified = false; // Reset verification status
    notifyListeners();
  }

  Future<void> updatePhone(String newPhone) async {
    await _repo.updatePhone(newPhone);
    phone = newPhone;
    isPhoneVerified = false; // Reset verification status
    notifyListeners();
  }

  // Mark as verified after OTP confirmation
  void markEmailVerified() {
    isEmailVerified = true;
    notifyListeners();
  }

  void markPhoneVerified() {
    isPhoneVerified = true;
    notifyListeners();
  }

  Future<void> changeProfilePhoto(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    final String path = picked.path;
    await updateProfilePic(path);
  }
}
