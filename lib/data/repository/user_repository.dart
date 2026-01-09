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
  final String updateEmailUrl;
  final String updatePhoneUrl;
  final String sendOtpUrl;
  final String verifyOtpUrl;

  UserRepository({
    this.loginUrl = "$baseUrl/login.php",
    this.registerUrl = "$baseUrl/register.php",
    this.kycUrl = "$baseUrl/delivery_kyc.php",
    this.updateEmailUrl = "$baseUrl/update_email.php",
    this.updatePhoneUrl = "$baseUrl/update_phone.php",
    this.sendOtpUrl = "$baseUrl/send_otp.php",
    this.verifyOtpUrl = "$baseUrl/verify_otp.php",
  });

  void clearUser() {
    print('🧹 [CLEAR_USER] Clearing old user data');
    DummyData.user = UserModel(
      id: '',
      name: '',
      email: '',
      phone: '',
      profilePic: '',
      role: '',
    );
    print('✅ [CLEAR_USER] User data cleared');
  }

  // -------- User Getters & Helpers --------
  UserModel getUser() {
    print('📋 [GET_USER] Fetching current user');
    print('   User ID: ${DummyData.user.id}');
    print('   Name: ${DummyData.user.name}');
    print('   Email: ${DummyData.user.email}');
    return DummyData.user;
  }

  Future<UserModel> getUserProfile() async {
    print('📋 [GET_PROFILE] Fetching user profile');
    await Future.delayed(const Duration(milliseconds: 500));
    return DummyData.user;
  }

  Future<void> logout() async {
    print('🚪 [LOGOUT] Logging out user');
    clearUser();
    await Future.delayed(const Duration(milliseconds: 300));
    print('✅ [LOGOUT] Logout complete');
  }

  void updateUserName(String newName) {
    print('✏️ [UPDATE_NAME] Updating user name to: $newName');
    DummyData.user = DummyData.user.copyWith(name: newName);
  }

  void updateProfilePic(String newUrl) {
    print('🖼️ [UPDATE_PIC] Updating profile pic to: $newUrl');
    DummyData.user = DummyData.user.copyWith(profilePic: newUrl);
  }

  /// ✅ Restore user session from saved data (used by AuthController)
  void restoreUserSession(UserModel user) {
    print('🔄 [RESTORE] Restoring user session to DummyData');
    print('   User ID: ${user.id}');
    print('   Name: ${user.name}');
    print('   Email: ${user.email}');
    print('   Role: ${user.role}');
    DummyData.user = user;
    print('✅ [RESTORE] User session restored successfully');
  }

  // ✅ ---------------- UPDATE EMAIL ----------------
  Future<void> updateEmail(String newEmail) async {
    print('\n════════════════════════════════════════');
    print('📧 [UPDATE_EMAIL] Starting email update');
    print('════════════════════════════════════════');

    final currentUser = getUser();
    final userId = currentUser.id;

    if (userId.isEmpty) {
      print('❌ [UPDATE_EMAIL] User not logged in');
      throw Exception('User not logged in. Please login first.');
    }

    print('🆔 [UPDATE_EMAIL] User ID: $userId');
    print('📧 [UPDATE_EMAIL] New Email: $newEmail');

    final uri = Uri.parse(updateEmailUrl);
    print('🌐 [UPDATE_EMAIL] API Endpoint: $uri');

    final Map<String, String> body = {
      'user_id': userId.trim(),
      'email': newEmail.trim(),
    };

    try {
      print('⏳ [UPDATE_EMAIL] Sending POST request...');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        },
        body: body,
        encoding: Encoding.getByName('utf-8'),
      ).timeout(const Duration(seconds: 30));

      print('📥 [UPDATE_EMAIL] Response received');
      print('   Status Code: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode != 200) {
        try {
          final data = jsonDecode(response.body);
          final msg = data['message'] ?? 'Failed to update email';
          throw Exception(msg);
        } catch (e) {
          if (e.toString().contains('Exception:')) rethrow;
          throw Exception('Server error ${response.statusCode}');
        }
      }

      final data = jsonDecode(response.body);

      if (data['success'] == false) {
        throw Exception(data['message'] ?? 'Failed to update email');
      }

      // Update local user data
      DummyData.user = DummyData.user.copyWith(email: newEmail);

      print('✅ [UPDATE_EMAIL] Email updated successfully!');
      print('════════════════════════════════════════\n');

    } on SocketException catch (e) {
      print('❌ [UPDATE_EMAIL] Network Error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      print('❌ [UPDATE_EMAIL] Error: $e');
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Failed to update email: ${e.toString()}');
    }
  }

  // ✅ ---------------- UPDATE PHONE ----------------
  Future<void> updatePhone(String newPhone) async {
    print('\n════════════════════════════════════════');
    print('📱 [UPDATE_PHONE] Starting phone update');
    print('════════════════════════════════════════');

    final currentUser = getUser();
    final userId = currentUser.id;

    if (userId.isEmpty) {
      print('❌ [UPDATE_PHONE] User not logged in');
      throw Exception('User not logged in. Please login first.');
    }

    print('🆔 [UPDATE_PHONE] User ID: $userId');
    print('📱 [UPDATE_PHONE] New Phone: $newPhone');

    final uri = Uri.parse(updatePhoneUrl);
    print('🌐 [UPDATE_PHONE] API Endpoint: $uri');

    final Map<String, String> body = {
      'user_id': userId.trim(),
      'phone': newPhone.trim(),
    };

    try {
      print('⏳ [UPDATE_PHONE] Sending POST request...');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        },
        body: body,
        encoding: Encoding.getByName('utf-8'),
      ).timeout(const Duration(seconds: 30));

      print('📥 [UPDATE_PHONE] Response received');
      print('   Status Code: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode != 200) {
        try {
          final data = jsonDecode(response.body);
          final msg = data['message'] ?? 'Failed to update phone';
          throw Exception(msg);
        } catch (e) {
          if (e.toString().contains('Exception:')) rethrow;
          throw Exception('Server error ${response.statusCode}');
        }
      }

      final data = jsonDecode(response.body);

      if (data['success'] == false) {
        throw Exception(data['message'] ?? 'Failed to update phone');
      }

      // Update local user data
      DummyData.user = DummyData.user.copyWith(phone: newPhone);

      print('✅ [UPDATE_PHONE] Phone updated successfully!');
      print('════════════════════════════════════════\n');

    } on SocketException catch (e) {
      print('❌ [UPDATE_PHONE] Network Error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      print('❌ [UPDATE_PHONE] Error: $e');
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Failed to update phone: ${e.toString()}');
    }
  }

  // ✅ ---------------- SEND OTP ----------------
  Future<void> sendOtp({
    required String destination,
    required String channel, // "email" or "phone"
  }) async {
    print('\n════════════════════════════════════════');
    print('📨 [SEND_OTP] Sending OTP');
    print('════════════════════════════════════════');

    final currentUser = getUser();
    final userId = currentUser.id;

    if (userId.isEmpty) {
      print('❌ [SEND_OTP] User not logged in');
      throw Exception('User not logged in. Please login first.');
    }

    print('🆔 [SEND_OTP] User ID: $userId');
    print('📧 [SEND_OTP] Destination: $destination');
    print('📱 [SEND_OTP] Channel: $channel');

    final uri = Uri.parse(sendOtpUrl);
    print('🌐 [SEND_OTP] API Endpoint: $uri');

    final Map<String, String> body = {
      'user_id': userId.trim(),
      'destination': destination.trim(),
      'channel': channel.toLowerCase().trim(),
    };

    try {
      print('⏳ [SEND_OTP] Sending POST request...');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        },
        body: body,
        encoding: Encoding.getByName('utf-8'),
      ).timeout(const Duration(seconds: 30));

      print('📥 [SEND_OTP] Response received');
      print('   Status Code: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode != 200) {
        try {
          final data = jsonDecode(response.body);
          final msg = data['message'] ?? 'Failed to send OTP';
          throw Exception(msg);
        } catch (e) {
          if (e.toString().contains('Exception:')) rethrow;
          throw Exception('Server error ${response.statusCode}');
        }
      }

      final data = jsonDecode(response.body);

      if (data['success'] == false) {
        throw Exception(data['message'] ?? 'Failed to send OTP');
      }

      print('✅ [SEND_OTP] OTP sent successfully!');
      print('════════════════════════════════════════\n');

    } on SocketException catch (e) {
      print('❌ [SEND_OTP] Network Error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      print('❌ [SEND_OTP] Error: $e');
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Failed to send OTP: ${e.toString()}');
    }
  }

  // ✅ ---------------- VERIFY OTP ----------------
  Future<bool> verifyOtp({
    required String destination,
    required String otp,
    required String channel, // "email" or "phone"
  }) async {
    print('\n════════════════════════════════════════');
    print('✅ [VERIFY_OTP] Verifying OTP');
    print('════════════════════════════════════════');

    final currentUser = getUser();
    final userId = currentUser.id;

    if (userId.isEmpty) {
      print('❌ [VERIFY_OTP] User not logged in');
      throw Exception('User not logged in. Please login first.');
    }

    print('🆔 [VERIFY_OTP] User ID: $userId');
    print('📧 [VERIFY_OTP] Destination: $destination');
    print('🔢 [VERIFY_OTP] OTP: $otp');
    print('📱 [VERIFY_OTP] Channel: $channel');

    final uri = Uri.parse(verifyOtpUrl);
    print('🌐 [VERIFY_OTP] API Endpoint: $uri');

    final Map<String, String> body = {
      'user_id': userId.trim(),
      'destination': destination.trim(),
      'otp': otp.trim(),
      'channel': channel.toLowerCase().trim(),
    };

    try {
      print('⏳ [VERIFY_OTP] Sending POST request...');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        },
        body: body,
        encoding: Encoding.getByName('utf-8'),
      ).timeout(const Duration(seconds: 30));

      print('📥 [VERIFY_OTP] Response received');
      print('   Status Code: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode != 200) {
        try {
          final data = jsonDecode(response.body);
          final msg = data['message'] ?? 'Failed to verify OTP';
          throw Exception(msg);
        } catch (e) {
          if (e.toString().contains('Exception:')) rethrow;
          throw Exception('Server error ${response.statusCode}');
        }
      }

      final data = jsonDecode(response.body);

      if (data['success'] == false) {
        throw Exception(data['message'] ?? 'Invalid OTP');
      }

      print('✅ [VERIFY_OTP] OTP verified successfully!');
      print('════════════════════════════════════════\n');

      return true;

    } on SocketException catch (e) {
      print('❌ [VERIFY_OTP] Network Error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      print('❌ [VERIFY_OTP] Error: $e');
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Failed to verify OTP: ${e.toString()}');
    }
  }

  // ✅ ---------------- LOGIN ----------------
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    print('\n════════════════════════════════════════');
    print('🔐 [LOGIN] Starting login process');
    print('════════════════════════════════════════');

    clearUser();

    final uri = Uri.parse(loginUrl);
    print('🌐 [LOGIN] API Endpoint: $uri');
    print('📧 [LOGIN] Email: $email');
    print('🔒 [LOGIN] Password length: ${password.length} characters');

    try {
      print('⏳ [LOGIN] Sending POST request...');

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
          print('⏱️ [LOGIN] Request timed out after 30 seconds');
          throw Exception('Connection timeout. Please try again.');
        },
      );

      print('📥 [LOGIN] Response received');
      print('   Status Code: ${response.statusCode}');
      print('   Headers: ${response.headers}');
      print('   Body Length: ${response.body.length} bytes');
      print('   Raw Body: ${response.body}');

      if (response.statusCode != 200) {
        print('❌ [LOGIN] Non-200 status code: ${response.statusCode}');
        try {
          final data = jsonDecode(response.body);
          print('   Error data: $data');
          final msg = data['message']?.toString() ?? 'Server error ${response.statusCode}';
          throw Exception(msg);
        } catch (e) {
          print('   Failed to parse error response: $e');
          if (e.toString().contains('Exception:')) rethrow;
          throw Exception('Server error: ${response.statusCode}');
        }
      }

      print('🔍 [LOGIN] Parsing JSON response...');
      final data = jsonDecode(response.body);
      print('   Parsed data type: ${data.runtimeType}');
      print('   Parsed data: $data');

      Map<String, dynamic> actualData = data;

      // Check if response has nested "data" field
      if (data.containsKey('data') && data['data'] is Map) {
        actualData = data['data'] as Map<String, dynamic>;
        print('📦 [LOGIN] Using nested data structure');
        print('   Nested data: $actualData');
      }

      print('✅ [LOGIN] Checking success status...');
      if (actualData['success'] == false) {
        final msg = actualData['message']?.toString() ?? 'Login failed';
        print('❌ [LOGIN] Login failed: $msg');
        throw Exception(msg);
      }

      print('👤 [LOGIN] Extracting user data...');
      final userData = actualData['user'];
      if (userData == null) {
        print('❌ [LOGIN] No user data in response');
        print('   Available keys: ${actualData.keys.toList()}');
        throw Exception('Invalid response: No user data');
      }

      print('📋 [LOGIN] Raw User Data:');
      print('   Type: ${userData.runtimeType}');
      print('   Content: $userData');
      print('   Keys: ${userData.keys.toList()}');

      // ✅ Parse user ID as String
      print('🔢 [LOGIN] Parsing user ID...');
      String userId = '';

      if (userData['uid'] != null) {
        print('   Found uid: ${userData['uid']}');
        userId = userData['uid'].toString();
        print('   Parsed from uid: $userId');
      } else if (userData['id'] != null) {
        print('   Found id: ${userData['id']}');
        userId = userData['id'].toString();
        print('   Parsed from id: $userId');
      } else if (userData['user_id'] != null) {
        print('   Found user_id: ${userData['user_id']}');
        userId = userData['user_id'].toString();
        print('   Parsed from user_id: $userId');
      } else {
        print('⚠️ [LOGIN] No ID field found in user data');
        print('   Available fields: ${userData.keys.toList()}');
      }

      print('🆔 [LOGIN] Final User ID: $userId');
      if (userId.isEmpty) {
        print('⚠️ [LOGIN] WARNING: User ID is empty - KYC will fail!');
      }

      // ✅ Parse role from response
      print('🔑 [LOGIN] Parsing user role...');
      String userRole = userData['role']?.toString() ?? '';

      if (userRole.isEmpty) {
        userRole = 'delivery';
        print('⚠️ [LOGIN] Role was empty, using fallback: $userRole');
      } else {
        print('✅ [LOGIN] Role found: $userRole');
      }

      print('🏗️ [LOGIN] Creating UserModel...');
      final user = UserModel(
        id: userId,
        name: userData['name']?.toString() ?? email.split('@')[0],
        email: userData['email']?.toString() ?? email,
        phone: userData['phone']?.toString() ?? '',
        profilePic: userData['profile_pic']?.toString() ?? '',
        role: userRole,
        isEmailVerified: userData['is_email_verified'] == 1 || userData['is_email_verified'] == true,
        isPhoneVerified: userData['is_phone_verified'] == 1 || userData['is_phone_verified'] == true,
      );

      print('✅ [LOGIN] UserModel created:');
      print('   ID: ${user.id}');
      print('   Name: ${user.name}');
      print('   Email: ${user.email}');
      print('   Phone: ${user.phone}');
      print('   Role: ${user.role}');
      print('   Email Verified: ${user.isEmailVerified}');
      print('   Phone Verified: ${user.isPhoneVerified}');

      DummyData.user = user;
      print('💾 [LOGIN] User saved to DummyData');
      print('✅ [LOGIN] Login successful!');
      print('════════════════════════════════════════\n');

      return user;

    } on SocketException catch (e) {
      print('❌ [LOGIN] SocketException caught');
      print('   Error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } on http.ClientException catch (e) {
      print('❌ [LOGIN] ClientException caught');
      print('   Error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } on FormatException catch (e) {
      print('❌ [LOGIN] FormatException caught');
      print('   Error: $e');
      throw Exception('Invalid response from server');
    } catch (e, stackTrace) {
      print('❌ [LOGIN] Unexpected error caught');
      print('   Error type: ${e.runtimeType}');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // ✅ ---------------- BASIC SIGNUP ----------------
  Future<void> signupBasic({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    print('\n════════════════════════════════════════');
    print('📝 [SIGNUP] Starting signup process');
    print('════════════════════════════════════════');

    clearUser();
    final uri = Uri.parse(registerUrl);

    print('🔍 [SIGNUP] Role parameter analysis:');
    print('   Role value: "$role"');
    print('   Role type: ${role.runtimeType}');

    final Map<String, String> body = {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role,
    };

    print('🌐 [SIGNUP] API Endpoint: $uri');
    print('📤 [SIGNUP] Request body:');
    body.forEach((key, value) {
      print('   $key: "$value"');
    });

    try {
      print('⏳ [SIGNUP] Sending POST request...');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        },
        body: body,
        encoding: Encoding.getByName('utf-8'),
      ).timeout(const Duration(seconds: 30));

      print('📥 [SIGNUP] Response received');
      print('   Status Code: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('❌ [SIGNUP] Server error: ${response.statusCode}');
        throw Exception('Server error ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      print('🔍 [SIGNUP] Parsed response: $data');
      print('   Response keys: ${data.keys.toList()}');

      if (data.containsKey('user') && data['user'] is Map) {
        final savedRole = data['user']['role'];
        print('📋 [SIGNUP] Role saved in database: "$savedRole"');
        if (savedRole != role) {
          print('⚠️ [SIGNUP] WARNING: Sent role "$role" but saved as "$savedRole"');
        }
      }

      bool isSuccess = false;

      if (data.containsKey('success')) {
        if (data['success'] == true) {
          print('✅ [SIGNUP] Success detected via success field = true');
          isSuccess = true;
        } else if (data['success'] == false) {
          final msg = data['message'] ?? 'Registration failed';
          print('❌ [SIGNUP] Registration failed: $msg');
          throw Exception(msg);
        }
      }

      if (!isSuccess && data.containsKey('token') && data.containsKey('user')) {
        print('✅ [SIGNUP] Success detected via token + user presence');
        isSuccess = true;
      }

      if (!isSuccess && (response.statusCode == 200 || response.statusCode == 201) && data.containsKey('user')) {
        print('✅ [SIGNUP] Success detected via status code + user data');
        isSuccess = true;
      }

      if (!isSuccess) {
        final msg = data['message'] ?? 'Registration failed - unexpected response format';
        print('❌ [SIGNUP] Registration failed: $msg');
        print('   Full response: $data');
        throw Exception(msg);
      }

      print('✅ [SIGNUP] Registration successful!');
      print('════════════════════════════════════════\n');

    } on SocketException catch (e) {
      print('❌ [SIGNUP] Network Error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } on TimeoutException catch (e) {
      print('❌ [SIGNUP] Timeout Error: $e');
      throw Exception('Request timeout. Please try again.');
    } catch (e, stackTrace) {
      print('❌ [SIGNUP] Error: $e');
      print('   Stack trace: $stackTrace');
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // ✅ ---------------- SUBMIT DELIVERY PARTNER KYC ----------------
  Future<void> submitDeliveryPartnerKyc({
    String? vehicleType,
    String? vehicleNumber,
    String? drivingLicense,
    String? aadharNumber,
    String? panNumber,
    String? bankAccountNumber,
    String? ifscCode,
  }) async {
    print('\n════════════════════════════════════════');
    print('🚗 [KYC] Starting KYC submission');
    print('════════════════════════════════════════');

    final uri = Uri.parse(kycUrl);
    print('🌐 [KYC] API Endpoint: $uri');

    print('👤 [KYC] Fetching logged-in user...');
    final currentUser = getUser();
    final userId = currentUser.id;

    print('🆔 [KYC] Auto-fetched User ID: $userId');
    print('👤 [KYC] User Details:');
    print('   Name: ${currentUser.name}');
    print('   Email: ${currentUser.email}');
    print('   Role: "${currentUser.role}"');

    if (currentUser.role.isEmpty) {
      print('⚠️ [KYC] WARNING: User role is empty!');
      print('   KYC may fail. Update user role in database to "delivery"');
    } else if (currentUser.role != 'delivery') {
      print('⚠️ [KYC] WARNING: Unexpected role: "${currentUser.role}"');
      print('   Expected "delivery"');
    }

    if (userId.isEmpty) {
      print('⚠️ [KYC] ERROR: User ID is empty!');
      throw Exception('User not logged in. Please login first.');
    }

    print('✅ [KYC] Validating fields...');
    if (vehicleType == null || vehicleType.isEmpty) {
      throw Exception('Vehicle type is required');
    }
    if (vehicleNumber == null || vehicleNumber.isEmpty) {
      throw Exception('Vehicle number is required');
    }
    if (drivingLicense == null || drivingLicense.isEmpty) {
      throw Exception('Driving license is required');
    }
    if (aadharNumber == null || aadharNumber.isEmpty) {
      throw Exception('Aadhar number is required');
    }
    if (panNumber == null || panNumber.isEmpty) {
      throw Exception('PAN number is required');
    }
    if (bankAccountNumber == null || bankAccountNumber.isEmpty) {
      throw Exception('Bank account number is required');
    }
    if (ifscCode == null || ifscCode.isEmpty) {
      throw Exception('IFSC code is required');
    }

    print('   ✓ All fields validated');

    final Map<String, String> body = {
      'user_id': userId.trim(),
      'vehicle_type': vehicleType.trim(),
      'vehicle_number': vehicleNumber.trim(),
      'driving_license': drivingLicense.trim(),
      'aadhar_number': aadharNumber.trim(),
      'pan_number': panNumber.trim(),
      'bank_account_number': bankAccountNumber.trim(),
      'ifsc_code': ifscCode.trim(),
    };

    print('📤 [KYC] Request Body:');
    body.forEach((key, value) {
      print('   $key: $value');
    });

    try {
      print('⏳ [KYC] Sending POST request...');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: body,
        encoding: Encoding.getByName('utf-8'),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏱️ [KYC] Request timed out after 30 seconds');
          throw Exception('Connection timeout. Please try again.');
        },
      );

      print('📥 [KYC] Response received');
      print('   Status Code: ${response.statusCode}');
      print('   Headers: ${response.headers}');
      print('   Body Length: ${response.body.length} bytes');
      print('   Raw Body: ${response.body}');

      if (response.body.isEmpty) {
        print('⚠️ [KYC] Empty response body received');
        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ [KYC] Status is success despite empty body');
          print('════════════════════════════════════════\n');
          return;
        } else {
          throw Exception('Server returned empty response with status ${response.statusCode}');
        }
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('❌ [KYC] Non-success status code: ${response.statusCode}');

        try {
          final data = jsonDecode(response.body);
          final errorMsg = data['error']?.toString() ??
              data['message']?.toString() ??
              'Server error ${response.statusCode}';
          throw Exception(errorMsg);
        } catch (e) {
          if (e.toString().contains('Exception:')) rethrow;
          throw Exception('Server error ${response.statusCode}');
        }
      }

      print('🔍 [KYC] Parsing JSON response...');
      final data = jsonDecode(response.body);
      print('   Parsed data: $data');

      if (data is Map) {
        if (data.containsKey('error')) {
          throw Exception(data['error'].toString());
        }
        if (data.containsKey('success') && data['success'] == false) {
          final msg = data['message'] ?? data['error'] ?? 'KYC submission failed';
          throw Exception(msg);
        }
      }

      print('✅ [KYC] Submitted Successfully!');
      print('📝 [KYC] Response: ${data['message'] ?? 'Success'}');
      print('════════════════════════════════════════\n');

    } on SocketException catch (e) {
      print('❌ [KYC] SocketException: $e');
      throw Exception('Network error. Please check your internet connection.');
    } on http.ClientException catch (e) {
      print('❌ [KYC] ClientException: $e');
      throw Exception('Network error. Please try again.');
    } on FormatException catch (e) {
      print('❌ [KYC] FormatException: $e');
      print('   Response was not valid JSON');
      throw Exception('Invalid response from server');
    } on TimeoutException catch (e) {
      print('❌ [KYC] TimeoutException: $e');
      throw Exception('Request timeout. Please try again.');
    } catch (e, stackTrace) {
      print('❌ [KYC] Unexpected Error:');
      print('   Type: ${e.runtimeType}');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('KYC submission failed: ${e.toString()}');
    }
  }
}
