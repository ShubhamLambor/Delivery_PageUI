// lib/services/delivery_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class DeliveryService {
  static const String baseUrl = 'https://svtechshant.com/tiffin/api';

  /// Accept an order
  static Future<Map<String, dynamic>> acceptOrder({
    required String orderId,
    required String deliveryPartnerId,
  }) async {
    try {
      debugPrint('✅ Accepting order...');
      debugPrint(' Order ID: $orderId');
      debugPrint(' Partner ID: $deliveryPartnerId');

      final response = await http.post(
        Uri.parse('$baseUrl/delivery/accept_order.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'order_id': orderId,
          'delivery_partner_id': deliveryPartnerId,
          'status': 'accepted',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('📥 Accept Response Status: ${response.statusCode}');
      debugPrint('📥 Accept Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);

          if (jsonData['status'] == 'success' || jsonData['success'] == true) {
            return {
              'success': true,
              'message': jsonData['message'] ?? 'Order accepted successfully',
              'order_id': jsonData['order_id'] ?? orderId,
              'delivery_partner_id': jsonData['delivery_partner_id'],
              'accepted_at': jsonData['accepted_at'],
              'debug_log': jsonData['debug_log'],
            };
          } else {
            return {
              'success': false,
              'message': jsonData['message'] ?? 'Failed to accept order',
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
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } on http.ClientException catch (e) {
      debugPrint('❌ Network Error: $e');
      return {
        'success': false,
        'message': 'Network error. Check your internet connection.',
        'error': e.toString(),
      };
    } catch (e) {
      debugPrint('❌ Accept Order Error: $e');
      return {
        'success': false,
        'message': 'Failed to accept order. Please try again.',
        'error': e.toString(),
      };
    }
  }

  /// Reject an order
  static Future<Map<String, dynamic>> rejectOrder({
    required String orderId,
    required String deliveryPartnerId,
    String? reason,
  }) async {
    try {
      debugPrint('❌ Rejecting order...');
      debugPrint(' Order ID: $orderId');
      debugPrint(' Partner ID: $deliveryPartnerId');
      debugPrint(' Reason: ${reason ?? "Not provided"}');

      final response = await http.post(
        Uri.parse('$baseUrl/delivery/reject_order.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'order_id': orderId,
          'delivery_partner_id': deliveryPartnerId,
          'reason': reason ?? 'Not available',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('📥 Reject Response Status: ${response.statusCode}');
      debugPrint('📥 Reject Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);

          if (jsonData['status'] == 'success' || jsonData['success'] == true) {
            return {
              'success': true,
              'message': jsonData['message'] ?? 'Order rejected',
              'order_id': jsonData['order_id'] ?? orderId,
              'rejected_at': jsonData['rejected_at'],
              'debug_log': jsonData['debug_log'],
            };
          } else {
            return {
              'success': false,
              'message': jsonData['message'] ?? 'Failed to reject order',
              'debug_log': jsonData['debug_log'],
            };
          }
        } catch (e) {
          debugPrint('⚠️ JSON Parse Error: $e');
          return {
            'success': false,
            'message': 'Invalid server response',
            'raw_response': response.body,
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } on http.ClientException catch (e) {
      debugPrint('❌ Network Error: $e');
      return {
        'success': false,
        'message': 'Network error. Check your internet connection.',
        'error': e.toString(),
      };
    } catch (e) {
      debugPrint('❌ Reject Order Error: $e');
      return {
        'success': false,
        'message': 'Failed to reject order. Please try again.',
        'error': e.toString(),
      };
    }
  }

  /// Get pending/new orders for delivery partner
  static Future<Map<String, dynamic>> getNewOrders({
    required String deliveryPartnerId,
  }) async {
    try {
      debugPrint('🔄 Fetching new orders for partner: $deliveryPartnerId');

      final response = await http.post(
        Uri.parse('$baseUrl/delivery/get_new_orders.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'delivery_partner_id': deliveryPartnerId,
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 New Orders Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);

          if (jsonData['status'] == 'success' || jsonData['success'] == true) {
            return {
              'success': true,
              'orders': jsonData['orders'] ?? [],
              'count': jsonData['count'] ?? 0,
              'message': jsonData['message'],
            };
          } else {
            return {
              'success': false,
              'message': jsonData['message'] ?? 'No new orders',
              'orders': [],
              'count': 0,
            };
          }
        } catch (e) {
          debugPrint('⚠️ JSON Parse Error: $e');
          return {
            'success': false,
            'message': 'Invalid server response',
            'orders': [],
            'count': 0,
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'orders': [],
          'count': 0,
        };
      }
    } catch (e) {
      debugPrint('❌ Get New Orders Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch orders',
        'orders': [],
        'count': 0,
      };
    }
  }

  /// Update order status (picked up, delivered, etc.)
  static Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String deliveryPartnerId,
    required String status, // 'picked_up', 'in_transit', 'delivered', 'cancelled'
    String? notes,
  }) async {
    try {
      debugPrint('🔄 Updating order status...');
      debugPrint(' Order ID: $orderId');
      debugPrint(' New Status: $status');

      final response = await http.post(
        Uri.parse('$baseUrl/delivery/update_order_status.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'order_id': orderId,
          'delivery_partner_id': deliveryPartnerId,
          'status': status,
          'notes': notes ?? '',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('📥 Status Update Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);

          if (jsonData['status'] == 'success' || jsonData['success'] == true) {
            return {
              'success': true,
              'message': jsonData['message'] ?? 'Status updated successfully',
              'order_id': jsonData['order_id'],
              'status': jsonData['new_status'] ?? status,
              'updated_at': jsonData['updated_at'],
            };
          } else {
            return {
              'success': false,
              'message': jsonData['message'] ?? 'Failed to update status',
            };
          }
        } catch (e) {
          debugPrint('⚠️ JSON Parse Error: $e');
          return {
            'success': false,
            'message': 'Invalid server response',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Update Status Error: $e');
      return {
        'success': false,
        'message': 'Failed to update status',
        'error': e.toString(),
      };
    }
  }

  /// Get delivery partner's active orders
  static Future<Map<String, dynamic>> getActiveOrders({
    required String deliveryPartnerId,
  }) async {
    try {
      debugPrint('🔄 Fetching active orders for partner: $deliveryPartnerId');

      final response = await http.post(
        Uri.parse('$baseUrl/delivery/get_active_orders.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'delivery_partner_id': deliveryPartnerId,
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('📥 Active Orders Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          return {
            'success': true,
            'orders': jsonData['orders'] ?? [],
            'count': jsonData['count'] ?? 0,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Invalid response',
            'orders': [],
            'count': 0,
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error',
          'orders': [],
          'count': 0,
        };
      }
    } catch (e) {
      debugPrint('❌ Get Active Orders Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch active orders',
        'orders': [],
        'count': 0,
      };
    }
  }
}
