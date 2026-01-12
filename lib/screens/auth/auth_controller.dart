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

  /// Whether initial restore from prefs is done
  bool _initialized = false;

  bool get loading => _loading;
  String? get error => _error;
  UserModel? get user => _user;
  bool get isInitialized => _initialized;

  /// Simple flag for UI
  bool get isLoggedIn => _user != null && (_user!.id.isNotEmpty);

  AuthController() {
    _loadUserFromPrefs();
  }

  /// RESTORE SESSION: Loads basic user info from storage when app starts
  Future<void> _loadUserFromPrefs() async {
    print('\n════════════════════════════════════════');
    print('🔄 [AUTH_CONTROLLER] Loading user from preferences...');
    print('════════════════════════════════════════');

    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedInFlag = prefs.getBool('isLoggedIn') ?? false;
    print(' isLoggedIn flag: $isLoggedInFlag');

    if (isLoggedInFlag) {
      print('✅ [AUTH_CONTROLLER] User session found');

      final userId = prefs.getString('userId') ?? '';
      final userName = prefs.getString('userName') ?? 'Delivery Partner';
      final userEmail = prefs.getString('userEmail') ?? '';
      final userPhone = prefs.getString('userPhone') ?? '';
      final userProfilePic = prefs.getString('userProfilePic') ?? '';
      final userRole = prefs.getString('userRole') ?? 'delivery';

      print(' Loaded from SharedPreferences:');
      print(' - User ID: $userId');
      print(' - Name: $userName');
      print(' - Email: $userEmail');
      print(' - Phone: $userPhone');
      print(' - Role: $userRole');

      if (userId.isEmpty) {
        print('⚠️ [AUTH_CONTROLLER] WARNING: Saved User ID is empty!');
        print(' Clearing invalid session...');
        await prefs.clear();
        _user = null;
        _error = 'Session invalid. Please login again.';
        _initialized = true;
        notifyListeners();
        print('════════════════════════════════════════\n');
        return;
      }

      // Reconstruct user model from saved prefs
      _user = UserModel(
        id: userId,
        name: userName,
        email: userEmail,
        phone: userPhone,
        profilePic: userProfilePic,
        role: userRole,
      );

      _userRepo.restoreUserSession(_user!);
      print('✅ [AUTH_CONTROLLER] Session restored successfully');
      print(' Active User ID: ${_user!.id}');
      print(' Active User Name: ${_user!.name}');
    } else {
      print('ℹ️ [AUTH_CONTROLLER] No saved session found');
      _user = null;
    }

    _initialized = true;
    notifyListeners();
    print('════════════════════════════════════════\n');
  }

  /// LOGIN: Authenticates with Backend API
  Future<bool> login(String email, String password) async {
    print('');
    print('═══════════════════════════════════════');
    print('🔐 [AUTH_CONTROLLER] Starting login...');
    print('═══════════════════════════════════════');
    print('📧 Email: $email');

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final loggedInUser = await _userRepo.login(email: email, password: password); // ✅ Renamed variable

      print('[AUTH_CONTROLLER] Login response received');
      print('  User ID: ${loggedInUser.id}');
      print('  User Name: ${loggedInUser.name}');
      print('  User Email: ${loggedInUser.email}');
      print('  User Phone: ${loggedInUser.phone}');
      print('  User Role: ${loggedInUser.role}');

      if (loggedInUser.id.isEmpty) {
        print('[AUTH_CONTROLLER] ❌ CRITICAL ERROR: User ID is empty!');
        _loading = false;
        _error = 'Login failed: Invalid user data from server';
        notifyListeners();
        return false;
      }

      // ✅ Now this correctly assigns to the class field
      _user = loggedInUser;

      // SAVE SESSION
      print('[AUTH_CONTROLLER] Saving user session to SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', loggedInUser.id);
      await prefs.setString('userEmail', loggedInUser.email);
      await prefs.setString('userName', loggedInUser.name);
      await prefs.setString('userPhone', loggedInUser.phone);
      await prefs.setString('userProfilePic', loggedInUser.profilePic);
      await prefs.setString('userRole', loggedInUser.role);

      final savedUserId = prefs.getString('userId');
      print('✅ Verification - Saved User ID: $savedUserId');

      _userRepo.restoreUserSession(loggedInUser);

      _loading = false;
      _error = null;
      _initialized = true;
      notifyListeners();

      print('[AUTH_CONTROLLER] ✅ Login successful!');
      print('  Session saved with User ID: ${loggedInUser.id}');
      print('═══════════════════════════════════════');

      return true;
    } catch (e) {
      _loading = false;

      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception:')) {
        errorMsg = errorMsg.replaceFirst('Exception:', '').trim();
      }
      if (errorMsg.startsWith('Login failed:')) {
        errorMsg = errorMsg.replaceFirst('Login failed:', '').trim();
      }

      _error = errorMsg;
      notifyListeners();

      print('[AUTH_CONTROLLER] ❌ Login failed: $errorMsg');
      print('═══════════════════════════════════════');

      return false;
    }
  }


  /// BASIC SIGNUP
  Future<bool> signupBasic({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    print('\n════════════════════════════════════════');
    print('📝 [AUTH_CONTROLLER] Starting basic signup...');
    print('════════════════════════════════════════');
    print(' Name: $name');
    print(' Email: $email');
    print(' Phone: $phone');

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _userRepo.signupBasic(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: 'delivery',
      );
      _loading = false;
      _error = null;
      notifyListeners();
      print('✅ [AUTH_CONTROLLER] Basic signup successful!');
      print('════════════════════════════════════════\n');
      return true;
    } catch (e) {
      _loading = false;
      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception:')) {
        errorMsg = errorMsg.replaceFirst('Exception:', '').trim();
      }
      if (errorMsg.startsWith('Registration failed:')) {
        errorMsg =
            errorMsg.replaceFirst('Registration failed:', '').trim();
      }
      _error = errorMsg;
      notifyListeners();
      print('❌ [AUTH_CONTROLLER] Signup failed: $errorMsg');
      print('════════════════════════════════════════\n');
      return false;
    }
  }

  /// FULL SIGNUP WITH AUTO-LOGIN
  Future<bool> signupWithKycLater({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    print('\n════════════════════════════════════════');
    print('📝 [AUTH_CONTROLLER] Starting full signup process...');
    print('════════════════════════════════════════');

    final signupSuccess = await signupBasic(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );

    if (!signupSuccess) {
      print('❌ [AUTH_CONTROLLER] Signup failed, aborting...');
      print('════════════════════════════════════════\n');
      return false;
    }

    print('✅ [AUTH_CONTROLLER] Account created successfully');
    print('🔐 [AUTH_CONTROLLER] Step 2: Auto-logging in...');

    final loginSuccess = await login(email, password);
    if (!loginSuccess) {
      print('⚠️ [AUTH_CONTROLLER] Auto-login failed after signup');
      _error =
      'Account created but login failed. Please login manually.';
      notifyListeners();
      print('════════════════════════════════════════\n');
      return false;
    }

    print('✅ [AUTH_CONTROLLER] Full signup completed!');
    print(' User ID: ${_user?.id}');
    print(' Ready for KYC prompt');
    print('════════════════════════════════════════\n');
    return true;
  }

  /// LOGOUT
  Future<void> logout() async {
    print('\n════════════════════════════════════════');
    print('🚪 [AUTH_CONTROLLER] Logging out...');
    print('════════════════════════════════════════');

    _user = null;
    await _userRepo.logout();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    print(' SharedPreferences cleared');
    print(' User data cleared');

    _initialized = true;
    _error = null;
    notifyListeners();

    print('✅ [AUTH_CONTROLLER] Logout complete');
    print('════════════════════════════════════════\n');
  }

  /// KYC helpers
  Future<bool> needsKyc() async {
    final prefs = await SharedPreferences.getInstance();
    final kycCompleted = prefs.getBool('kycCompleted') ?? false;
    print('🔍 [AUTH_CONTROLLER] Checking KYC status');
    print(' KYC Completed: $kycCompleted');
    print(' Needs KYC: ${!kycCompleted}');
    return !kycCompleted;
  }

  Future<void> markKycCompleted() async {
    print('✅ [AUTH_CONTROLLER] Marking KYC as completed');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('kycCompleted', true);
    print(' KYC completion status saved to SharedPreferences');
  }

  /// Single source of truth for user id
  String? getCurrentUserId() {
    if (_user == null) {
      print('⚠️ [AUTH_CONTROLLER] getCurrentUserId: No user logged in');
      return null;
    }
    if (_user!.id.isEmpty) {
      print(
          '⚠️ [AUTH_CONTROLLER] getCurrentUserId: User ID is empty (invalid)');
      return null;
    }
    print('✅ [AUTH_CONTROLLER] getCurrentUserId: ${_user!.id}');
    return _user!.id;
  }

  /// Validate user session
  Future<bool> isValidSession() async {
    print('\n🔍 [AUTH_CONTROLLER] Validating user session...');
    if (_user == null) {
      print(' ❌ No user object');
      return false;
    }
    if (_user!.id.isEmpty) {
      print(' ❌ User ID is empty (invalid)');
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final isLoggedInFlag = prefs.getBool('isLoggedIn') ?? false;
    final savedUserId = prefs.getString('userId') ?? '';

    print(' isLoggedIn: $isLoggedInFlag');
    print(' Memory User ID: ${_user!.id}');
    print(' Saved User ID: $savedUserId');

    if (!isLoggedInFlag) {
      print(' ❌ Not logged in');
      return false;
    }
    if (savedUserId.isEmpty) {
      print(' ❌ Saved User ID is empty');
      return false;
    }
    if (_user!.id != savedUserId) {
      print(' ⚠️ User ID mismatch');
      return false;
    }

    print(' ✅ Session is valid');
    return true;
  }
}
