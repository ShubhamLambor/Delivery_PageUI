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
    print('\n════════════════════════════════════════');
    print('🔄 [AUTH_CONTROLLER] Loading user from preferences...');
    print('════════════════════════════════════════');

    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    print('   isLoggedIn flag: $isLoggedIn');

    if (isLoggedIn) {
      print('✅ [AUTH_CONTROLLER] User session found');

      final userId = prefs.getString('userId') ?? '';  // ✅ getString
      final userName = prefs.getString('userName') ?? 'Delivery Partner';
      final userEmail = prefs.getString('userEmail') ?? '';
      final userPhone = prefs.getString('userPhone') ?? '';
      final userProfilePic = prefs.getString('userProfilePic') ?? '';
      final userRole = prefs.getString('userRole') ?? 'delivery';

      print('   Loaded from SharedPreferences:');
      print('   - User ID: $userId');
      print('   - Name: $userName');
      print('   - Email: $userEmail');
      print('   - Phone: $userPhone');
      print('   - Role: $userRole');

      // ✅ UPDATED: Check for empty string
      if (userId.isEmpty) {
        print('⚠️ [AUTH_CONTROLLER] WARNING: Saved User ID is empty!');
        print('   Clearing invalid session...');
        await prefs.clear();
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

      // ✅ Also restore to DummyData for repository access
      _userRepo.restoreUserSession(_user!);

      print('✅ [AUTH_CONTROLLER] Session restored successfully');
      print('   Active User ID: ${_user!.id}');
      print('   Active User Name: ${_user!.name}');
      notifyListeners();
    } else {
      print('ℹ️ [AUTH_CONTROLLER] No saved session found');
    }
    print('════════════════════════════════════════\n');
  }

  /// LOGIN: Authenticates with Backend API
  Future<bool> login(String email, String password) async {
    print('\n════════════════════════════════════════');
    print('🔐 [AUTH_CONTROLLER] Starting login...');
    print('════════════════════════════════════════');
    print('   Email: $email');

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _userRepo.login(email: email, password: password);

      print('📋 [AUTH_CONTROLLER] Login response received');
      print('   User ID: ${user.id}');
      print('   User Name: ${user.name}');
      print('   User Email: ${user.email}');
      print('   User Phone: ${user.phone}');
      print('   User Role: ${user.role}');

      // ✅ UPDATED: Validate User ID is not empty
      if (user.id.isEmpty) {
        print('❌ [AUTH_CONTROLLER] CRITICAL ERROR: User ID is empty!');
        print('   This means the backend did not return a valid user ID.');
        print('   Check your PHP login.php response format.');

        _loading = false;
        _error = 'Login failed: Invalid user data from server';
        notifyListeners();
        return false;
      }

      _user = user;

      // SAVE SESSION: Store critical data
      print('💾 [AUTH_CONTROLLER] Saving user session to SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', user.id);  // ✅ setString
      await prefs.setString('userEmail', user.email);
      await prefs.setString('userName', user.name);
      await prefs.setString('userPhone', user.phone);
      await prefs.setString('userProfilePic', user.profilePic);
      await prefs.setString('userRole', user.role);

      // ✅ Verify data was saved correctly
      final savedUserId = prefs.getString('userId');
      print('   Verification - Saved User ID: $savedUserId');

      if (savedUserId != user.id) {
        print('⚠️ [AUTH_CONTROLLER] WARNING: Saved ID mismatch!');
      }

      _loading = false;
      _error = null;
      notifyListeners();

      print('✅ [AUTH_CONTROLLER] Login successful!');
      print('   Session saved with User ID: ${user.id}');
      print('════════════════════════════════════════\n');
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

      print('❌ [AUTH_CONTROLLER] Login failed: $errorMsg');
      print('════════════════════════════════════════\n');
      return false;
    }
  }

  /// ✅ BASIC SIGNUP (Step 1: Create account only)
  Future<bool> signupBasic({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    print('\n════════════════════════════════════════');
    print('📝 [AUTH_CONTROLLER] Starting basic signup...');
    print('════════════════════════════════════════');
    print('   Name: $name');
    print('   Email: $email');
    print('   Phone: $phone');

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
        errorMsg = errorMsg.replaceFirst('Registration failed:', '').trim();
      }

      _error = errorMsg;
      notifyListeners();

      print('❌ [AUTH_CONTROLLER] Signup failed: $errorMsg');
      print('════════════════════════════════════════\n');
      return false;
    }
  }

  /// ✅ FULL SIGNUP WITH AUTO-LOGIN
  Future<bool> signupWithKycLater({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    print('\n════════════════════════════════════════');
    print('📝 [AUTH_CONTROLLER] Starting full signup process...');
    print('════════════════════════════════════════');

    // Step 1: Create account
    print('📝 [AUTH_CONTROLLER] Step 1: Creating account...');
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

    // Step 2: Auto-login after successful signup
    final loginSuccess = await login(email, password);

    if (!loginSuccess) {
      print('⚠️ [AUTH_CONTROLLER] Auto-login failed after signup');
      _error = 'Account created but login failed. Please login manually.';
      notifyListeners();
      print('════════════════════════════════════════\n');
      return false;
    }

    print('✅ [AUTH_CONTROLLER] Full signup completed!');
    print('   User ID: ${_user?.id}');
    print('   Ready for KYC prompt');
    print('════════════════════════════════════════\n');
    return true;
  }

  /// LOGOUT: Clears Backend Session & Local Storage
  Future<void> logout() async {
    print('\n════════════════════════════════════════');
    print('🚪 [AUTH_CONTROLLER] Logging out...');
    print('════════════════════════════════════════');

    _user = null;

    // Clear repository data
    await _userRepo.logout();

    // Clear stored preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    print('   SharedPreferences cleared');
    print('   User data cleared');

    notifyListeners();

    print('✅ [AUTH_CONTROLLER] Logout complete');
    print('════════════════════════════════════════\n');
  }

  /// ✅ Check if user needs KYC
  Future<bool> needsKyc() async {
    final prefs = await SharedPreferences.getInstance();
    final kycCompleted = prefs.getBool('kycCompleted') ?? false;

    print('🔍 [AUTH_CONTROLLER] Checking KYC status');
    print('   KYC Completed: $kycCompleted');
    print('   Needs KYC: ${!kycCompleted}');

    return !kycCompleted;
  }

  /// ✅ Mark KYC as completed
  Future<void> markKycCompleted() async {
    print('✅ [AUTH_CONTROLLER] Marking KYC as completed');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('kycCompleted', true);
    print('   KYC completion status saved to SharedPreferences');
  }

  /// ✅ Get current user ID (with validation)
  String? getCurrentUserId() {
    if (_user == null) {
      print('⚠️ [AUTH_CONTROLLER] getCurrentUserId: No user logged in');
      return null;
    }

    if (_user!.id.isEmpty) {
      print('⚠️ [AUTH_CONTROLLER] getCurrentUserId: User ID is empty (invalid)');
      return null;
    }

    print('✅ [AUTH_CONTROLLER] getCurrentUserId: ${_user!.id}');
    return _user!.id;
  }

  /// ✅ Validate user session
  Future<bool> isValidSession() async {
    print('\n🔍 [AUTH_CONTROLLER] Validating user session...');

    if (_user == null) {
      print('   ❌ No user object');
      return false;
    }

    if (_user!.id.isEmpty) {
      print('   ❌ User ID is empty (invalid)');
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final savedUserId = prefs.getString('userId') ?? '';

    print('   isLoggedIn: $isLoggedIn');
    print('   Memory User ID: ${_user!.id}');
    print('   Saved User ID: $savedUserId');

    if (!isLoggedIn) {
      print('   ❌ Not logged in');
      return false;
    }

    if (savedUserId.isEmpty) {
      print('   ❌ Saved User ID is empty');
      return false;
    }

    if (_user!.id != savedUserId) {
      print('   ⚠️ User ID mismatch');
      return false;
    }

    print('   ✅ Session is valid');
    return true;
  }
}
