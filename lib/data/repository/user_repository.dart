// lib/data/repository/user_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/user_model.dart';
import 'dummy_data.dart';

class UserRepository {
  /// Base API URL
  static const String baseUrl = "https://svtechshant.com/tiffin/api";

  /// Full URL to login endpoint
  final String loginUrl;

  /// Full URL to register endpoint
  final String registerUrl;

  UserRepository({
    this.loginUrl = "$baseUrl/login.php",
    this.registerUrl = "$baseUrl/register.php",
  });

  // -------- dummy helpers (keep existing UI working) --------
  UserModel getUser() => DummyData.user;

  Future<UserModel> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return DummyData.user;
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void updateUserName(String newName) {
    DummyData.user = DummyData.user.copyWith(name: newName);
  }

  void updateProfilePic(String newUrl) {
    DummyData.user = DummyData.user.copyWith(profilePic: newUrl);
  }

  // ---------------- REAL LOGIN (login.php) ----------------
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse(loginUrl);

    try {
      // ✅ CHANGED: Send as form-urlencoded data
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'email': email,
          'password': password,
        },
        encoding: Encoding.getByName('utf-8'),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please try again.');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      // ✅ Updated to match your PHP response format
      if (data['success'] == false || data['token'] == null) {
        final msg = data['message']?.toString() ?? 'Invalid email or password';
        throw Exception(msg);
      }

      // Parse user data from 'user' object
      final userData = data['user'];

      // Parse uid (user ID)
      final int userId = userData['uid'] is int
          ? userData['uid'] as int
          : int.tryParse(userData['uid'].toString()) ?? 0;

      final user = UserModel(
        id: userId,
        name: userData['name']?.toString() ?? email.split('@')[0],
        email: userData['email']?.toString() ?? email,
        phone: userData['phone']?.toString() ?? '',
        profilePic: userData['profile_pic']?.toString() ?? '',
        role: userData['role']?.toString() ?? 'delivery_partners',
      );

      DummyData.user = user; // keep dummy in sync

      return user;
    } on http.ClientException {
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // ---------------- SIGNUP/REGISTER (register.php) ----------------
  // lib/data/repository/user_repository.dart

  Future<void> signup({
    required String username,
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
    final uri = Uri.parse(registerUrl);

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'name': username,
          'email': email,
          'password': password,
          'phone': phone,
          'vehicle_type': vehicleType,
          'vehicle_number': vehicleNumber,
          'driving_license': drivingLicense,
          'aadhar_number': aadharNumber,
          'pan_number': panNumber,
          'bank_account_number': bankAccountNumber,
          'ifsc_code': ifscCode,
        },
        encoding: Encoding.getByName('utf-8'),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please try again.');
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        try {
          final data = jsonDecode(response.body);
          final errorMsg = data['message']?.toString() ??
              'Server error ${response.statusCode}';
          throw Exception(errorMsg);
        } catch (e) {
          throw Exception('Error ${response.statusCode}: ${response.body}');
        }
      }

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        final errorMsg = data['message']?.toString() ?? 'Registration failed';
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Registration failed: ${e.toString()}');
    }
  }
}
