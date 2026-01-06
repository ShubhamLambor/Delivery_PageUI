// lib/services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class ApiService {
  // 🔥 REPLACE WITH YOUR ACTUAL BACKEND URL
  static const String baseUrl = 'https://svtechshant.com/tiffin/api';

  /// Update delivery partner online/offline status
  static Future<Map<String, dynamic>> updatePartnerStatus({
    required String partnerId,
    required bool isOnline,
    String? partnerName,
  }) async {
    try {
      debugPrint('🔄 Sending status update...');
      debugPrint('   Partner ID: $partnerId');
      debugPrint('   Status: ${isOnline ? "1" : "0"}');

      final response = await http.post(
        Uri.parse('$baseUrl/delivery/toggle_status.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'uid': partnerId,  // Your PHP expects 'uid'
          'status': isOnline ? '1' : '0',  // Send as string '1' or '0'
        },
      );

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);

          // Your PHP returns "status": "success" or "error"
          if (jsonData['status'] == 'success') {
            return {
              'success': true,
              'message': jsonData['message'],
              'is_online': jsonData['is_online'],
              'debug_log': jsonData['debug_log'],  // Optional: for debugging
            };
          } else {
            return {
              'success': false,
              'message': jsonData['message'] ?? 'Update failed',
              'debug_log': jsonData['debug_log'],
            };
          }
        } catch (e) {
          debugPrint('⚠️ JSON Parse Error: $e');
          debugPrint('Raw Response: ${response.body}');
          return {
            'success': false,
            'message': 'Invalid server response',
            'raw_response': response.body,
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      debugPrint('❌ API Error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
        'error': e.toString(),
      };
    }
  }

  /// Get current partner status from backend (optional)
  static Future<Map<String, dynamic>> getPartnerStatus({
    required String partnerId,
  }) async {
    try {
      debugPrint('🔄 Fetching status for partner: $partnerId');

      final response = await http.post(
        Uri.parse('$baseUrl/get_status.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'uid': partnerId,
        },
      );

      debugPrint('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          return jsonData;
        } catch (e) {
          debugPrint('⚠️ Invalid JSON: ${response.body}');
          return {
            'success': false,
            'message': 'Invalid server response'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      debugPrint('❌ API Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch status'
      };
    }
  }
}
