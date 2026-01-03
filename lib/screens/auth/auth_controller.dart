// lib/screens/auth/auth_controller.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../data/repository/user_repository.dart';

class AuthController extends ChangeNotifier {
  final UserRepository _userRepo = UserRepository();

  bool _loading = false;
  String? _error;
  UserModel? _user;

  bool get loading => _loading;
  String? get error => _error;
  UserModel? get user => _user;

  AuthController() {
    _loadUserFromPrefs();
  }

  /// RESTORE SESSION: Loads basic user info from storage when app starts
  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      // Reconstruct basic user model from saved prefs to keep UI populated
      // You might want to fetch the full profile from API here if needed
      _user = UserModel(
        id: prefs.getInt('userId') ?? 0,
        name: prefs.getString('userName') ?? 'Delivery Partner',
        email: prefs.getString('userEmail') ?? '',
        phone: prefs.getString('userPhone') ?? '',
        profilePic: '', // Load if you saved it
        role: 'delivery_partner',
      );
      notifyListeners();
    }
  }

  /// LOGIN: Authenticates with Backend API
  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _userRepo.login(email: email, password: password);
      _user = user;

      // SAVE SESSION: Store critical data so we don't ask for login again
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      // Save basic details to restore session later
      if (user != null) {
        await prefs.setInt('userId', user.id);
        await prefs.setString('userEmail', user.email);
        await prefs.setString('userName', user.name);
        await prefs.setString('userPhone', user.phone);
      }

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

  /// SIGNUP: Registers with Backend API
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

  /// LOGOUT: Clears Backend Session & Local Storage
  Future<void> logout() async {
    _user = null;

    // Clear stored preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // This removes 'isLoggedIn' and all user data

    notifyListeners();
  }
}
