// lib/data/repository/user_repository.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

  // ✅ Add method to clear user data
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

  // ✅ ---------------- REAL LOGIN with NESTED DATA HANDLING ----------------
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // ✅ Clear old user data first
    clearUser();

    final uri = Uri.parse(loginUrl);

    print('════════════════════════════════════════');
    print('🌐 LOGIN API REQUEST');
    print('📍 URL: $uri');
    print('📧 Email: $email');
    print('🔒 Password: $password');
    print('🔒 Password length: ${password.length}');
    print('🔒 Password bytes: ${password.codeUnits}');
    print('📤 Body: {email: $email, password: $password}');
    print('════════════════════════════════════════');

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

      print('════════════════════════════════════════');
      print('📥 LOGIN RESPONSE');
      print('📊 Status: ${response.statusCode}');
      print('📦 Body: ${response.body}');
      print('════════════════════════════════════════');

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
      print('📋 Raw parsed data: $data');

      // ✅ FIX: Handle nested "data" structure from backend
      Map<String, dynamic> actualData = data;

      // Check if response has nested "data" field
      if (data.containsKey('data') && data['data'] is Map) {
        actualData = data['data'] as Map<String, dynamic>;
        print('📋 Using nested data structure: $actualData');
      }

      // ✅ Check success and token in the actual data
      if (actualData['success'] == false) {
        final msg = actualData['message']?.toString() ?? 'Login failed';
        print('❌ Login validation failed: $msg');
        throw Exception(msg);
      }

      if (actualData['token'] == null || actualData['token'].toString().isEmpty) {
        print('❌ No token received from server');
        throw Exception('Invalid response from server');
      }

      final userData = actualData['user'];

      if (userData == null) {
        print('❌ No user data received from server');
        throw Exception('Invalid response from server');
      }

      print('👤 User data: $userData');

      // ✅ Parse user ID
      final int userId = userData['uid'] is int
          ? userData['uid'] as int
          : int.tryParse(userData['uid'].toString()) ?? 0;

      // ✅ Create user model with fresh data
      final user = UserModel(
        id: userId,
        name: userData['name']?.toString() ?? email.split('@')[0],
        email: userData['email']?.toString() ?? email,
        phone: userData['phone']?.toString() ?? '',
        profilePic: userData['profile_pic']?.toString() ?? '',
        role: userData['role']?.toString() ?? 'delivery',
      );

      print('✅ Login successful! User: ${user.name} (${user.email})');

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
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // ✅ ---------------- BASIC SIGNUP with ENHANCED DEBUGGING ----------------
  Future<void> signupBasic({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    // ✅ Clear old user data before signup
    clearUser();

    final uri = Uri.parse(registerUrl);

    final Map<String, String> body = {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role,
    };

    print('════════════════════════════════════════');
    print('🌐 SIGNUP API REQUEST');
    print('📍 URL: $uri');
    print('📤 Body: $body');
    print('🔒 Password: $password');
    print('🔒 Password length: ${password.length}');
    print('🔒 Password bytes: ${password.codeUnits}');
    print('════════════════════════════════════════');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
        encoding: Encoding.getByName('utf-8'),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please try again.');
        },
      );

      print('════════════════════════════════════════');
      print('📥 SIGNUP RESPONSE');
      print('📊 Status: ${response.statusCode}');
      print('📦 Body: ${response.body}');
      print('════════════════════════════════════════');

      if (response.statusCode == 404) {
        throw Exception('API endpoint not found. Check register.php file.');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        try {
          final data = jsonDecode(response.body);
          final errorMsg = data['error']?.toString() ??
              data['message']?.toString() ??
              'Server error ${response.statusCode}';
          throw Exception(errorMsg);
        } catch (e) {
          if (e.toString().contains('Exception:')) rethrow;
          throw Exception('Server returned ${response.statusCode}: ${response.body}');
        }
      }

      final data = jsonDecode(response.body);
      if (data.containsKey('success') && data['success'] != true) {
        final errorMsg = data['error']?.toString() ??
            data['message']?.toString() ??
            'Registration failed';
        throw Exception(errorMsg);
      }

      print('✅ Registration successful!');

    } on SocketException catch (e) {
      print('❌ SocketException: $e');
      throw Exception('No internet connection. Please check your network.');
    } on TlsException catch (e) {
      print('❌ TlsException: $e');
      throw Exception('SSL certificate error. Contact support.');
    } on TimeoutException catch (e) {
      print('❌ TimeoutException: $e');
      throw Exception('Connection timeout. Please try again.');
    } on http.ClientException catch (e) {
      print('❌ ClientException: $e');
      throw Exception('Connection failed: ${e.message}');
    } on FormatException catch (e) {
      print('❌ FormatException: $e');
      throw Exception('Invalid server response format');
    } catch (e) {
      print('❌ Unknown Error: $e');
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Registration failed: $e');
    }
  }

  // ---------------- FULL DELIVERY PARTNER SIGNUP (for future use) ----------------
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
    // ✅ Clear old user data
    clearUser();

    final uri = Uri.parse(registerUrl);

    final Map<String, String> body = {
      'name': username,
      'email': email,
      'password': password,
      'phone': phone,
      'role': 'delivery_partner',
      'vehicle_type': vehicleType,
      'vehicle_number': vehicleNumber,
      'driving_license': drivingLicense,
      'aadhar_number': aadharNumber,
      'pan_number': panNumber,
      'bank_account_number': bankAccountNumber,
      'ifsc_code': ifscCode,
    };

    print('════════════════════════════════════════');
    print('🌐 FULL DELIVERY PARTNER SIGNUP API REQUEST');
    print('📍 URL: $uri');
    print('📤 Body: $body');
    print('════════════════════════════════════════');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
        encoding: Encoding.getByName('utf-8'),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out after 30 seconds');
        },
      );

      print('════════════════════════════════════════');
      print('📥 RESPONSE');
      print('📊 Status: ${response.statusCode}');
      print('📦 Body: ${response.body}');
      print('════════════════════════════════════════');

      if (response.statusCode == 404) {
        throw Exception('API endpoint not found. Check if file is named register.php or signup.php');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        try {
          final data = jsonDecode(response.body);
          final errorMsg = data['error']?.toString() ??
              data['message']?.toString() ??
              'Server error ${response.statusCode}';
          throw Exception(errorMsg);
        } catch (e) {
          if (e.toString().contains('Exception:')) rethrow;
          throw Exception('Server returned ${response.statusCode}: ${response.body}');
        }
      }

      final data = jsonDecode(response.body);
      if (data.containsKey('success') && data['success'] != true) {
        final errorMsg = data['error']?.toString() ??
            data['message']?.toString() ??
            'Registration failed';
        throw Exception(errorMsg);
      }

      print('✅ Registration successful!');

    } on SocketException catch (e) {
      print('❌ SocketException: $e');
      throw Exception('No internet connection. Please check your network.');
    } on TlsException catch (e) {
      print('❌ TlsException: $e');
      throw Exception('SSL certificate error. Contact support.');
    } on TimeoutException catch (e) {
      print('❌ TimeoutException: $e');
      throw Exception('Connection timeout. Please try again.');
    } on http.ClientException catch (e) {
      print('❌ ClientException: $e');
      throw Exception('Connection failed: ${e.message}');
    } on FormatException catch (e) {
      print('❌ FormatException: $e');
      throw Exception('Invalid server response format');
    } catch (e) {
      print('❌ Unknown Error: $e');
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Registration failed: $e');
    }
  }
}
