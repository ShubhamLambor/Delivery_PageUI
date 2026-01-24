// lib/services/delivery_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/delivery_model.dart';

class DeliveryService {
  static const String baseUrl = 'https://svtechshant.com/tiffin/api';

  /// Helper method for all status updates - Single unified endpoint
  static Future<Map<String, dynamic>> _updateStatus({
    required String action,
    required String orderId,
    required String deliveryPartnerId,
    String? reason,
    String? notes,
  }) async {
    try {
      debugPrint('🔄 Updating order status...');
      debugPrint('   Action: $action');
      debugPrint('   Order ID: $orderId');
      debugPrint('   Partner ID: $deliveryPartnerId');
      if (reason != null) debugPrint('   Reason: $reason');
      if (notes != null) debugPrint('   Notes: $notes');

      final response = await http
          .post(
        Uri.parse('$baseUrl/delivery/order_delivery_status.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'action': action,
          'orderid': orderId,
          'deliverypartnerid': deliveryPartnerId,
          if (reason != null) 'reason': reason,
          if (notes != null) 'notes': notes,
        },
      )
          .timeout(const Duration(seconds: 15));

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          if (jsonData['success'] == true) {
            return {
              'success': true,
              'message':
              jsonData['message'] ?? 'Action completed successfully',
              'order_id': jsonData['order_id'] ?? orderId,
              'action': jsonData['action'] ?? action,
              'status': jsonData['status'],
              'data': jsonData['data'],
            };
          } else {
            return {
              'success': false,
              'message': jsonData['message'] ?? 'Action failed',
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
      debugPrint('❌ API Error: $e');
      return {
        'success': false,
        'message': 'Failed to complete action. Please try again.',
        'error': e.toString(),
      };
    }
  }

  /// Get active deliveries for delivery partner
  static Future<List<DeliveryModel>> getActiveDeliveries(
      String partnerId,
      ) async {
    try {
      debugPrint('📋 Fetching active deliveries for partner: $partnerId');

      final response = await http
          .post(
        Uri.parse('$baseUrl/delivery/get_active_orders.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'delivery_partner_id': partnerId,
        },
      )
          .timeout(const Duration(seconds: 10));

      debugPrint(
          '📥 Active Deliveries Response Status: ${response.statusCode}');
      debugPrint('📥 Active Deliveries Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          debugPrint('📥 Active Deliveries Parsed Data: $jsonData');

          if (jsonData['success'] == true ||
              jsonData['status'] == 'success') {
            final List ordersJson = jsonData['orders'] ?? [];
            debugPrint('📦 Found ${ordersJson.length} orders in response');

            final List<DeliveryModel> deliveries =
            ordersJson.map((orderJson) {
              debugPrint(
                  '   📋 Parsing order: ${orderJson['order_id']} - Status: ${orderJson['status']}');
              return DeliveryModel.fromJson(orderJson);
            }).toList();

            debugPrint('✅ Fetched ${deliveries.length} active deliveries');
            return deliveries;
          } else {
            debugPrint('ℹ️ No active deliveries: ${jsonData['message']}');
            return [];
          }
        } catch (e) {
          debugPrint('⚠️ JSON Parse Error: $e');
          debugPrint('   Raw response: ${response.body}');
          return [];
        }
      } else {
        debugPrint('❌ Server Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Get Active Deliveries Error: $e');
      return [];
    }
  }

  /// 1. Accept Order
  static Future<Map<String, dynamic>> acceptOrder({
    required String orderId,
    required String deliveryPartnerId,
  }) async {
    debugPrint('✅ Accepting order...');
    return _updateStatus(
      action: 'accept',
      orderId: orderId,
      deliveryPartnerId: deliveryPartnerId,
    );
  }

  /// 2. Reject Order
  static Future<Map<String, dynamic>> rejectOrder({
    required String orderId,
    required String deliveryPartnerId,
    String? reason,
  }) async {
    debugPrint('❌ Rejecting order...');
    return _updateStatus(
      action: 'reject',
      orderId: orderId,
      deliveryPartnerId: deliveryPartnerId,
      reason: reason ?? 'No reason provided',
    );
  }

  /// 3. Mark Reached Pickup Location
  static Future<Map<String, dynamic>> markReachedPickup({
    required String orderId,
    required String deliveryPartnerId,
  }) async {
    debugPrint('📍 Marking reached pickup location...');
    return _updateStatus(
      action: 'reached_pickup',
      orderId: orderId,
      deliveryPartnerId: deliveryPartnerId,
    );
  }

  /// 4. Mark Order as Picked Up
  static Future<Map<String, dynamic>> markPickedUp({
    required String orderId,
    required String deliveryPartnerId,
  }) async {
    debugPrint('📦 Marking order as picked up...');
    return _updateStatus(
      action: 'picked_up',
      orderId: orderId,
      deliveryPartnerId: deliveryPartnerId,
    );
  }

  /// 5. Mark Order as In Transit / Out for Delivery
  static Future<Map<String, dynamic>> markInTransit({
    required String orderId,
    required String deliveryPartnerId,
  }) async {
    debugPrint('🚚 Marking order as in transit...');
    return _updateStatus(
      action: 'in_transit',
      orderId: orderId,
      deliveryPartnerId: deliveryPartnerId,
    );
  }

  /// 6. Mark Reached Delivery Location
  static Future<Map<String, dynamic>> markReachedDelivery({
    required String orderId,
    required String deliveryPartnerId,
  }) async {
    debugPrint('📍 Marking reached delivery location...');
    return _updateStatus(
      action: 'reached_delivery',
      orderId: orderId,
      deliveryPartnerId: deliveryPartnerId,
    );
  }

  /// 7. Mark Order as Delivered
  static Future<Map<String, dynamic>> markDelivered({
    required String orderId,
    required String deliveryPartnerId,
    String? notes,
  }) async {
    debugPrint('✅ Marking order as delivered...');
    return _updateStatus(
      action: 'delivered',
      orderId: orderId,
      deliveryPartnerId: deliveryPartnerId,
      notes: notes,
    );
  }

  /// 8. Cancel Order
  static Future<Map<String, dynamic>> cancelOrder({
    required String orderId,
    required String deliveryPartnerId,
    String? reason,
  }) async {
    debugPrint('🚫 Canceling order...');
    return _updateStatus(
      action: 'cancelled',
      orderId: orderId,
      deliveryPartnerId: deliveryPartnerId,
      reason: reason ?? 'Cancelled by delivery partner',
    );
  }

  /// 9. Start Delivery (When leaving pickup location)
  static Future<Map<String, dynamic>> startDelivery({
    required String orderId,
    required String deliveryPartnerId,
  }) async {
    debugPrint('🚀 Starting delivery...');
    return _updateStatus(
      action: 'start_delivery',
      orderId: orderId,
      deliveryPartnerId: deliveryPartnerId,
    );
  }

  /// ✅ Check for pending assignments for delivery partner
  static Future<Map<String, dynamic>> checkPendingAssignments(
      String partnerId,
      ) async {
    try {
      debugPrint('🔍 Checking pending assignments for partner: $partnerId');

      final response = await http
          .post(
        Uri.parse('$baseUrl/delivery/get_pending_assignments.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'delivery_partner_id': partnerId,
        },
      )
          .timeout(const Duration(seconds: 10));

      debugPrint(
          '📥 Pending Assignments Response Status: ${response.statusCode}');
      debugPrint('📥 Pending Assignments Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          debugPrint('📥 Pending Assignments Data: $jsonData');

          return {
            'success': jsonData['success'] ?? false,
            'has_pending': jsonData['has_pending'] ?? false,
            'assignment': jsonData['assignment'],
            'message': jsonData['message'] ?? 'No pending assignments',
          };
        } catch (e) {
          debugPrint('⚠️ JSON Parse Error: $e');
          return {
            'success': false,
            'has_pending': false,
            'assignment': null,
            'message': 'Invalid server response',
          };
        }
      } else {
        return {
          'success': false,
          'has_pending': false,
          'assignment': null,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('❌ Check Pending Assignments Error: $e');
      return {
        'success': false,
        'has_pending': false,
        'assignment': null,
        'message': 'Failed to check pending assignments',
      };
    }
  }

  /// Get pending/new orders for delivery partner
  static Future<Map<String, dynamic>> getNewOrders({
    required String deliveryPartnerId,
  }) async {
    try {
      debugPrint('🔄 Fetching new orders for partner: $deliveryPartnerId');

      final response = await http
          .post(
        Uri.parse('$baseUrl/delivery/get_new_orders.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'delivery_partner_id': deliveryPartnerId,
        },
      )
          .timeout(const Duration(seconds: 10));

      debugPrint('📥 New Orders Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);

          if (jsonData['status'] == 'success' ||
              jsonData['success'] == true) {
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

  /// Get delivery partner's active orders
  static Future<Map<String, dynamic>> getActiveOrders({
    required String deliveryPartnerId,
  }) async {
    try {
      debugPrint('🔄 Fetching active orders for partner: $deliveryPartnerId');

      final response = await http
          .post(
        Uri.parse('$baseUrl/delivery/get_active_orders.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'delivery_partner_id': deliveryPartnerId,
        },
      )
          .timeout(const Duration(seconds: 10));

      debugPrint('📥 Active Orders Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);

          if (jsonData['status'] == 'success' ||
              jsonData['success'] == true) {
            return {
              'success': true,
              'orders': jsonData['orders'] ?? [],
              'count': jsonData['count'] ?? 0,
            };
          } else {
            return {
              'success': false,
              'message': jsonData['message'] ?? 'No active orders',
              'orders': [],
              'count': 0,
            };
          }
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
          'message': 'Server error: ${response.statusCode}',
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

  /// Get single order details
  static Future<Map<String, dynamic>> getOrderDetails({
    required String orderId,
    required String deliveryPartnerId,
  }) async {
    try {
      debugPrint('🔍 Fetching order details: $orderId');

      final response = await http
          .post(
        Uri.parse('$baseUrl/delivery/get_order.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'order_id': orderId,
          'delivery_partner_id': deliveryPartnerId,
        },
      )
          .timeout(const Duration(seconds: 10));

      debugPrint('📥 Order Details Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);

          if (jsonData['success'] == true) {
            return {
              'success': true,
              'order': jsonData['order'],
            };
          } else {
            return {
              'success': false,
              'message': jsonData['message'] ?? 'Order not found',
            };
          }
        } catch (e) {
          return {
            'success': false,
            'message': 'Invalid response',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error',
        };
      }
    } catch (e) {
      debugPrint('❌ Get Order Details Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch order details',
      };
    }
  }

  /// Get order history for delivery partner
  static Future<Map<String, dynamic>> getOrderHistory({
    required String deliveryPartnerId,
    int? limit,
  }) async {
    try {
      debugPrint('📜 Fetching order history for partner: $deliveryPartnerId');

      final response = await http
          .post(
        Uri.parse('$baseUrl/delivery/get_order_history.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'delivery_partner_id': deliveryPartnerId,
          if (limit != null) 'limit': limit.toString(),
        },
      )
          .timeout(const Duration(seconds: 10));

      debugPrint('📥 Order History Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);

          if (jsonData['success'] == true) {
            return {
              'success': true,
              'orders': jsonData['orders'] ?? [],
              'count': jsonData['count'] ?? 0,
              'total_earnings': jsonData['total_earnings'] ?? 0.0,
            };
          } else {
            return {
              'success': false,
              'message': jsonData['message'] ?? 'No order history',
              'orders': [],
              'count': 0,
            };
          }
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
      debugPrint('❌ Get Order History Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch order history',
        'orders': [],
        'count': 0,
      };
    }
  }

  /// ✅ NEW: Get delivery history with filters (date range and status)
  static Future<Map<String, dynamic>> getDeliveryHistory({
    required String deliveryPartnerId,
    DateTime? startDate,
    DateTime? endDate,
    String status = 'all',
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      debugPrint('📋 Fetching delivery history with filters...');
      debugPrint('   Partner: $deliveryPartnerId');
      if (startDate != null || endDate != null) {
        debugPrint('   Date: ${startDate?.toString().split(' ')[0] ?? 'All'} - ${endDate?.toString().split(' ')[0] ?? 'All'}');
      }
      debugPrint('   Status: $status');

      final Map<String, String> body = {
        'delivery_partner_id': deliveryPartnerId,
        'status': status,
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (startDate != null) {
        body['start_date'] = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      }
      if (endDate != null) {
        body['end_date'] = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
      }

      final response = await http
          .post(
        Uri.parse('$baseUrl/delivery/get_delivery_history.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: body,
      )
          .timeout(const Duration(seconds: 15));

      debugPrint('📥 Delivery History Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);

          if (jsonData['success'] == true) {
            debugPrint('✅ Fetched ${jsonData['count']} deliveries from history');
            return {
              'success': true,
              'deliveries': jsonData['deliveries'] ?? [],
              'count': jsonData['count'] ?? 0,
              'total_count': jsonData['total_count'] ?? 0,
              'has_more': jsonData['has_more'] ?? false,
            };
          } else {
            return {
              'success': false,
              'message': jsonData['message'] ?? 'No delivery history',
              'deliveries': [],
              'count': 0,
            };
          }
        } catch (e) {
          debugPrint('⚠️ JSON Parse Error: $e');
          return {
            'success': false,
            'message': 'Invalid response',
            'deliveries': [],
            'count': 0,
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'deliveries': [],
          'count': 0,
        };
      }
    } catch (e) {
      debugPrint('❌ Get Delivery History Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch delivery history',
        'deliveries': [],
        'count': 0,
      };
    }
  }

  /// Get delivery partner stats
  static Future<Map<String, dynamic>> getPartnerStats({
    required String deliveryPartnerId,
  }) async {
    try {
      debugPrint('📊 Fetching partner stats: $deliveryPartnerId');

      final response = await http
          .post(
        Uri.parse('$baseUrl/delivery/get_partner_stats.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'deliverypartnerid': deliveryPartnerId,
        },
      )
          .timeout(const Duration(seconds: 10));

      debugPrint('📥 Partner Stats Response: ${response.statusCode}');
      debugPrint('📥 Partner Stats Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);

          if (jsonData['success'] == true) {
            return {
              'success': true,
              'stats': jsonData['stats'] ?? {},
              'total_deliveries': jsonData['totaldeliveries'] ?? 0,
              'total_earnings': jsonData['totalearnings'] ?? 0.0,
              'rating': jsonData['rating'] ?? 0.0,
            };
          } else {
            return {
              'success': false,
              'message': jsonData['message'] ?? 'No stats available',
            };
          }
        } catch (e) {
          return {
            'success': false,
            'message': 'Invalid response',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error',
        };
      }
    } catch (e) {
      debugPrint('❌ Get Partner Stats Error: $e');
      return {
        'success': false,
        'message': 'Failed to fetch partner stats',
      };
    }
  }

  /// Update delivery partner location
  static Future<Map<String, dynamic>> updateLocation({
    required String deliveryPartnerId,
    required double latitude,
    required double longitude,
    String? orderId,
  }) async {
    try {
      debugPrint('📍 Updating location: $latitude, $longitude');

      final response = await http
          .post(
        Uri.parse('$baseUrl/delivery/update_location.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'delivery_partner_id': deliveryPartnerId,
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          if (orderId != null) 'order_id': orderId,
        },
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          return {
            'success': jsonData['success'] ?? false,
            'message': jsonData['message'] ?? 'Location updated',
          };
        } catch (e) {
          return {'success': false, 'message': 'Invalid response'};
        }
      } else {
        return {'success': false, 'message': 'Server error'};
      }
    } catch (e) {
      debugPrint('❌ Update Location Error: $e');
      return {'success': false, 'message': 'Failed to update location'};
    }
  }
}
