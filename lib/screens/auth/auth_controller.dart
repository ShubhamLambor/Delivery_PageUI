// lib/screens/auth/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../data/repository/user_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController() {
    _loadCurrentUser();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepo = UserRepository();

  bool _loading = false;
  String? _error;
  UserModel? _user;

  bool get loading => _loading;
  String? get error => _error;
  UserModel? get user => _user;

  Future<void> _loadCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null && _user == null) {
      _user = UserModel(
        id: 0,
        name: firebaseUser.displayName ??
            firebaseUser.email ??
            'Delivery Partner',
        email: firebaseUser.email ?? '',
        phone: '',
        profilePic: firebaseUser.photoURL ?? '',
        role: 'delivery_partner', // ✅ Fixed: singular, not plural
      );
      notifyListeners();
    }
  }

  /// LOGIN USING backend login.php
  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _userRepo.login(email: email, password: password);
      _user = user;
      _loading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      // Clean up error message
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception:')) {
        errorMsg = errorMsg.replaceFirst('Exception:', '').trim();
      }
      if (errorMsg.startsWith('Login failed:')) {
        errorMsg = errorMsg.replaceFirst('Login failed:', '').trim();
      }
      _error = errorMsg;
      notifyListeners();
      return false;
    }
  }

  /// ✅ UPDATED SIGNUP with all delivery partner fields
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String vehicleType,
    required String vehicleNumber,
    required String drivingLicense,
    required String aadharNumber,
    required String panNumber,
    required String bankAccountNumber,
    required String ifscCode,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _userRepo.signup(
        username: name,
        email: email,
        password: password,
        phone: phone,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        drivingLicense: drivingLicense,
        aadharNumber: aadharNumber,
        panNumber: panNumber,
        bankAccountNumber: bankAccountNumber,
        ifscCode: ifscCode,
      );
      _loading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      // Clean up error message
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception:')) {
        errorMsg = errorMsg.replaceFirst('Exception:', '').trim();
      }
      if (errorMsg.startsWith('Registration failed:')) {
        errorMsg = errorMsg.replaceFirst('Registration failed:', '').trim();
      }
      _error = errorMsg;
      notifyListeners();
      return false;
    }
  }

  /// IMPROVED LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
    _user = null;

    // Clear stored preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('userEmail');

    notifyListeners();
  }
}
