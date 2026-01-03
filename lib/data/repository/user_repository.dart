// lib/data/repository/user_repository.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../models/user_model.dart';
import 'dummy_data.dart';

class UserRepository {
  static const String baseUrl = "https://svtechshant.com/tiffin/api";
  final String loginUrl;
  final String registerUrl;
  final String kycUrl;

  UserRepository({
    this.loginUrl = "$baseUrl/login.php",
    this.registerUrl = "$baseUrl/register.php",
    this.kycUrl = "$baseUrl/delivery_partners.php",
  });

  void clearUser() {
    print('🧹 Clearing old user data');
    DummyData.user = UserModel(
      id: 0,
      name: '',
      email: '',
      phone: '',
      profilePic: '',
      role: '',
    );
  }

  // -------- dummy helpers (keep existing UI working) --------
  UserModel getUser() => DummyData.user;

  Future<UserModel> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return DummyData.user;
  }

  Future<void> logout() async {
    clearUser(); // Clear user data on logout
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void updateUserName(String newName) {
    DummyData.user = DummyData.user.copyWith(name: newName);
  }

  void updateProfilePic(String newUrl) {
    DummyData.user = DummyData.user.copyWith(profilePic: newUrl);
  }

  // ✅ ---------------- REAL LOGIN with ROBUST ID PARSING ----------------
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // ✅ Clear old user data first
    clearUser();

    final uri = Uri.parse(loginUrl);

    print('════════════════════════════════════════');
    print('🌐 LOGIN API REQUEST: $uri');
    print('📧 Email: $email');

    try {
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

      print('📥 LOGIN RESPONSE: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode != 200) {
        print('❌ Login failed with status: ${response.statusCode}');
        try {
          final data = jsonDecode(response.body);
          final msg = data['message']?.toString() ?? 'Server error ${response.statusCode}';
          throw Exception(msg);
        } catch (e) {
          if (e.toString().contains('Exception:')) rethrow;
          throw Exception('Server error: ${response.statusCode}');
        }
      }

      final data = jsonDecode(response.body);
      Map<String, dynamic> actualData = data;

      // Check if response has nested "data" field
      if (data.containsKey('data') && data['data'] is Map) {
        actualData = data['data'] as Map<String, dynamic>;
        print('📋 Using nested data structure');
      }

      if (actualData['success'] == false) {
        final msg = actualData['message']?.toString() ?? 'Login failed';
        throw Exception(msg);
      }

      final userData = actualData['user'];
      if (userData == null) {
        throw Exception('Invalid response: No user data');
      }

      print('👤 Raw User Data: $userData');

      // ✅ ROBUST ID PARSING LOGIC
      // Checks 'uid', 'id', and 'user_id' to find a valid ID
      int userId = 0;
      if (userData['uid'] != null) {
        userId = int.tryParse(userData['uid'].toString()) ?? 0;
      } else if (userData['id'] != null) {
        userId = int.tryParse(userData['id'].toString()) ?? 0;
      } else if (userData['user_id'] != null) {
        userId = int.tryParse(userData['user_id'].toString()) ?? 0;
      }

      print('🆔 Parsed User ID: $userId');
      if (userId == 0) print('⚠️ WARNING: User ID is 0. KYC updates will fail.');

      // ✅ Create user model with fresh data
      final user = UserModel(
        id: userId,
        name: userData['name']?.toString() ?? email.split('@')[0],
        email: userData['email']?.toString() ?? email,
        phone: userData['phone']?.toString() ?? '',
        profilePic: userData['profile_pic']?.toString() ?? '',
        role: userData['role']?.toString() ?? 'delivery',
        // Optional: Parse vehicle number if available in login response
        // vehicleNumber: userData['vehicle_number']?.toString(),
      );

      // ✅ Store the NEW user data
      DummyData.user = user;
      return user;

    } on SocketException catch (e) {
      print('❌ SocketException: $e');
      throw Exception('Network error. Please check your internet connection.');
    } on http.ClientException catch (e) {
      print('❌ ClientException: $e');
      throw Exception('Network error. Please check your internet connection.');
    } on FormatException catch (e) {
      print('❌ FormatException: $e');
      throw Exception('Invalid response from server');
    } catch (e) {
      print('❌ Login Error: $e');
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // ✅ ---------------- BASIC SIGNUP (Unchanged) ----------------
  Future<void> signupBasic({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    clearUser();
    final uri = Uri.parse(registerUrl);
    final Map<String, String> body = {
      'name': name, 'email': email, 'password': password, 'phone': phone, 'role': role,
    };

    print('🌐 SIGNUP API REQUEST: $uri');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      ).timeout(const Duration(seconds: 30));

      print('📥 SIGNUP RESPONSE: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Server error ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) throw Exception(data['message'] ?? 'Registration failed');

      print('✅ Registration successful!');

    } catch (e) {
      print('❌ Signup Error: $e');
      rethrow;
    }
  }

  // ---------------- FULL DELIVERY PARTNER SIGNUP (Legacy) ----------------
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
    // Legacy full signup code (kept for reference, uses registerUrl)
    clearUser();
    final uri = Uri.parse(registerUrl);
    final Map<String, String> body = {
      'name': username, 'email': email, 'password': password, 'phone': phone,
      'role': 'delivery_partner', 'vehicle_type': vehicleType,
      'vehicle_number': vehicleNumber, 'driving_license': drivingLicense,
      'aadhar_number': aadharNumber, 'pan_number': panNumber,
      'bank_account_number': bankAccountNumber, 'ifsc_code': ifscCode,
    };

    try {
      final response = await http.post(uri, body: body);
      if (response.statusCode != 200) throw Exception('Failed');
    } catch (e) { rethrow; }
  }


  // ✅ ---------------- NEW: SUBMIT KYC (Called from Home/Profile) ----------------
  Future<void> submitDeliveryPartnerKyc({
    required int userId,
    required String vehicleType,
    required String vehicleNumber,
    required String drivingLicense,
    required String aadharNumber,
    required String panNumber,
    required String bankAccountNumber,
    required String ifscCode,
  }) async {
    final uri = Uri.parse(kycUrl); // delivery_partners.php

    print('════════════════════════════════════════');
    print('🌐 SUBMITTING KYC DATA to $uri');

    if (userId == 0) {
      print('❌ ERROR: User ID is 0. Aborting request.');
      throw Exception('Invalid User ID. Please re-login.');
    }

    final Map<String, String> body = {
      'user_id': userId.toString(),
      'vehicle_type': vehicleType,
      'vehicle_number': vehicleNumber,
      'driving_license': drivingLicense,
      'aadhar_number': aadharNumber,
      'pan_number': panNumber,
      'bank_account_number': bankAccountNumber,
      'ifsc_code': ifscCode,
    };

    print('📤 Body: $body');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      print('📥 KYC RESPONSE: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Server error ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('success') && data['success'] == false) {
        throw Exception(data['message'] ?? 'KYC update failed');
      }

      print('✅ KYC Submitted Successfully!');

    } catch (e) {
      print('❌ KYC Error: $e');
      rethrow;
    }
  }
}
