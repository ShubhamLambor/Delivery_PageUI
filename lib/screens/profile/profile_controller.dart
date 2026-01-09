// lib/screens/profile/profile_controller.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repository/user_repository.dart';

class ProfileController extends ChangeNotifier {
  final UserRepository _repo = UserRepository();
  final ImagePicker _picker = ImagePicker();

  String name = '';
  String email = '';
  String phone = '';
  String profilePic = '';

  // Verification status
  bool isEmailVerified = false;
  bool isPhoneVerified = false;
  bool isLoading = false;

  // Getter for the UI
  String? get profilePhotoUrl => profilePic.isNotEmpty ? profilePic : null;

  ProfileController() {
    loadUserData();
  }

  Future<void> loadUserData() async {
    isLoading = true;
    notifyListeners();

    final user = await _repo.getUserProfile();
    name = user.name;
    email = user.email;
    phone = user.phone ?? '';
    profilePic = user.profilePic;

    // Load verification status from backend
    isEmailVerified = user.isEmailVerified ?? false;
    isPhoneVerified = user.isPhoneVerified ?? false;

    isLoading = false;
    notifyListeners();
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
