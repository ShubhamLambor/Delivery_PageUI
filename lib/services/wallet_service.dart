// lib/services/wallet_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WalletService {
  static const String baseUrl = 'https://svtechshant.com/tiffin/api/transactions'; // Adjust path if needed

  /// Fetch Wallet Balance
  static Future<Map<String, dynamic>> getBalance(String partnerId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/wallet_balance.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'owner_id': partnerId,
          'owner_type': 'delivery',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // ✅ If no wallet row exists in DB, backend returns null. Default to 0.
        if (decoded == null) {
          return {
            'balance': 0.0,
            'locked_balance': 0.0,
            'available': 0.0
          };
        }

        return decoded as Map<String, dynamic>;
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      debugPrint('Wallet API Error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  /// Request a Withdrawal
  static Future<Map<String, dynamic>> requestWithdrawal(String partnerId, double amount) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment_request.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'owner_id': partnerId,
          'owner_type': 'delivery',
          'amount': amount.toString(),
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  /// Fetch Statement History
  static Future<List<dynamic>> getStatements(String partnerId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/statement.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'owner_id': partnerId,
          'owner_type': 'delivery',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
      }
      return [];
    } catch (e) {
      debugPrint('Statement API Error: $e');
      return [];
    }
  }
}