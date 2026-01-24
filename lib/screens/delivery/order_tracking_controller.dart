// lib/screens/delivery/order_tracking_controller.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../services/delivery_service.dart';

class OrderTrackingController extends ChangeNotifier {
  final String orderId;
  final String deliveryPartnerId;

  // Base URL for API
  static const String baseUrl = 'https://svtechshant.com/tiffin/api';

  OrderTrackingController({
    required this.orderId,
    required this.deliveryPartnerId,
  });

  // State
  bool isLoading = false;
  String orderStatus = 'accepted'; // Default fallback

  // Order Details
  String customerName = '';
  String customerPhone = '';
  String deliveryAddress = '';
  String messName = '';
  String messAddress = '';
  String messPhone = '';
  double orderAmount = 0.0;
  double deliveryFee = 0.0;
  String paymentMethod = '';
  List<Map<String, dynamic>> items = [];

  // Location
  double? pickupLat;
  double? pickupLng;
  double? deliveryLat;
  double? deliveryLng;

  // Timings
  DateTime? acceptedAt;
  DateTime? reachedPickupAt;
  DateTime? pickedUpAt;
  DateTime? deliveredAt;

  /// ✅ Helper method for robust coordinate parsing
  double? _parseCoordinate(dynamic value) {
    if (value == null) return null;

    // Already a double
    if (value is double) return value;

    // Already an int
    if (value is int) return value.toDouble();

    // String parsing
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return double.tryParse(trimmed);
    }

    // Fallback
    return null;
  }

  /// ✅ Validation getters
  bool get hasValidPickupCoordinates {
    return pickupLat != null &&
        pickupLng != null &&
        pickupLat != 0.0 &&
        pickupLng != 0.0;
  }

  bool get hasValidDeliveryCoordinates {
    return deliveryLat != null &&
        deliveryLng != null &&
        deliveryLat != 0.0 &&
        deliveryLng != 0.0;
  }

  /// Load order details from backend
  Future<void> loadOrderDetails(String orderId) async {
    isLoading = true;
    notifyListeners();

    try {
      debugPrint('📋 Loading order details for: $orderId');

      // Call the backend API
      final response = await http.post(
        Uri.parse('$baseUrl/delivery/get_order_details.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        encoding: Encoding.getByName('utf-8'),
        body: {
          'order_id': orderId,
          'delivery_partner_id': deliveryPartnerId,
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final order = data['order'];

          // Handle empty or null status - default to 'accepted'
          final rawStatus = order['status'];
          if (rawStatus == null || rawStatus.toString().trim().isEmpty) {
            orderStatus = 'accepted';
            debugPrint('⚠️ Order status was empty, defaulting to "accepted"');
          } else {
            orderStatus = rawStatus.toString();
          }

          customerName = order['customer_name'] ?? '';
          customerPhone = order['customer_phone'] ?? '';
          deliveryAddress = order['delivery_address'] ?? '';
          messName = order['mess_name'] ?? '';
          messAddress = order['mess_address'] ?? '';
          messPhone = order['mess_phone'] ?? '';
          orderAmount = double.tryParse(order['total_amount'].toString()) ?? 0.0;
          deliveryFee = double.tryParse(order['delivery_fee'].toString()) ?? 0.0;
          paymentMethod = order['payment_method'] ?? '';

          // ✅ Enhanced coordinate parsing with helper + fallback
          pickupLat = _parseCoordinate(order['pickup_latitude']);
          pickupLng = _parseCoordinate(order['pickup_longitude']);
          deliveryLat = _parseCoordinate(order['delivery_latitude']);
          deliveryLng = _parseCoordinate(order['delivery_longitude']);

          // ✅ Fallback to customer_address coordinates if delivery coords missing
          if (!hasValidDeliveryCoordinates) {
            debugPrint('⚠️ Delivery coordinates missing, checking customer_address...');
            deliveryLat = _parseCoordinate(order['customer_latitude']) ??
                _parseCoordinate(order['customer_address_latitude']);
            deliveryLng = _parseCoordinate(order['customer_longitude']) ??
                _parseCoordinate(order['customer_address_longitude']);
          }

          // ✅ Debug logging - Shows coordinate values after parsing
          debugPrint('📍 Coordinates parsed:');
          debugPrint('   Pickup: ${pickupLat ?? "null"}, ${pickupLng ?? "null"}');
          debugPrint('   Delivery: ${deliveryLat ?? "null"}, ${deliveryLng ?? "null"}');
          debugPrint('   Valid Pickup: $hasValidPickupCoordinates');
          debugPrint('   Valid Delivery: $hasValidDeliveryCoordinates');

          // Parse order items
          if (order['items'] != null && order['items'] is List) {
            items = (order['items'] as List).map((item) => {
              'name': item['item_name'],
              'quantity': item['quantity'],
              'price': item['price'],
              'subtotal': item['subtotal'],
            }).toList();
          }

          // Parse timestamps
          if (order['accepted_at'] != null) {
            acceptedAt = DateTime.tryParse(order['accepted_at']);
          }
          if (order['reached_pickup_at'] != null) {
            reachedPickupAt = DateTime.tryParse(order['reached_pickup_at']);
          }
          if (order['picked_up_at'] != null) {
            pickedUpAt = DateTime.tryParse(order['picked_up_at']);
          }
          if (order['delivered_at'] != null) {
            deliveredAt = DateTime.tryParse(order['delivered_at']);
          }

          debugPrint('✅ Order details loaded successfully');
          debugPrint('   Customer: $customerName');
          debugPrint('   Mess: $messName');
          debugPrint('   Amount: ₹$orderAmount');
          debugPrint('   Delivery Fee: ₹$deliveryFee');
          debugPrint('   Status: $orderStatus');
          debugPrint('   Items: ${items.length}');
        } else {
          debugPrint('❌ Failed to load order: ${data['message']}');
        }
      } else {
        debugPrint('❌ HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error loading order: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  /// Mark as reached pickup location
  Future<bool> markReachedPickup() async {
    try {
      debugPrint('📍 Marking reached pickup for order: $orderId...');

      final result = await DeliveryService.markReachedPickup(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
      );

      if (result['success'] == true) {
        // Update status from backend response or use fallback
        if (result['status'] != null && result['status'].toString().isNotEmpty) {
          orderStatus = result['status'].toString();
        } else {
          orderStatus = 'reached_pickup';
        }

        reachedPickupAt = DateTime.now();

        // ✅ Auto-reload after markReachedPickup() - Refreshes coordinates
        debugPrint('🔄 Auto-reloading order details after reached pickup...');
        await loadOrderDetails(orderId);

        debugPrint('✅ Marked as reached pickup successfully');
        debugPrint('📊 New status: $orderStatus');
        return true;
      } else {
        debugPrint('❌ Failed to mark reached pickup: ${result['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error marking reached pickup: $e');
      return false;
    }
  }

  /// Mark order as picked up from mess/restaurant
  Future<bool> markPickedUp() async {
    try {
      debugPrint('📦 Marking order $orderId as picked up...');

      final result = await DeliveryService.markPickedUp(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
      );

      if (result['success'] == true) {
        // Update status from backend response
        if (result['status'] != null && result['status'].toString().isNotEmpty) {
          orderStatus = result['status'].toString();
        } else {
          orderStatus = 'out_for_delivery';
        }

        pickedUpAt = DateTime.now();

        // ✅ Auto-reload after markPickedUp() - Refreshes coordinates
        debugPrint('🔄 Auto-reloading order details after picked up...');
        await loadOrderDetails(orderId);

        debugPrint('✅ Order marked as picked up successfully');
        debugPrint('📊 New status: $orderStatus');
        return true;
      } else {
        debugPrint('❌ Failed to mark as picked up: ${result['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error marking picked up: $e');
      return false;
    }
  }

  /// Mark order as in transit (en route to customer)
  Future<bool> markInTransit() async {
    try {
      debugPrint('🚗 Marking order $orderId as in transit...');

      final result = await DeliveryService.markInTransit(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
      );

      if (result['success'] == true) {
        orderStatus = 'in_transit';
        notifyListeners();
        debugPrint('✅ Order marked as in transit successfully');
        return true;
      } else {
        debugPrint('❌ Failed to mark as in transit: ${result['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error marking in transit: $e');
      return false;
    }
  }

  /// Mark order as delivered to customer
  Future<bool> markDelivered() async {
    try {
      debugPrint('🎉 Marking order $orderId as delivered...');

      final result = await DeliveryService.markDelivered(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
        notes: 'Delivered successfully',
      );

      if (result['success'] == true) {
        orderStatus = 'delivered';
        deliveredAt = DateTime.now();
        notifyListeners();
        debugPrint('✅ Order marked as delivered successfully');
        return true;
      } else {
        debugPrint('❌ Failed to mark as delivered: ${result['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error marking delivered: $e');
      return false;
    }
  }

  /// Get total distance between pickup and delivery points
  /// ✅ Validation in totalDistance - Checks for 0.0 values
  String get totalDistance {
    if (!hasValidPickupCoordinates || !hasValidDeliveryCoordinates) {
      debugPrint('⚠️ Cannot calculate distance: Invalid coordinates');
      return '--';
    }

    final dist = _calculateDistance(
        pickupLat!,
        pickupLng!,
        deliveryLat!,
        deliveryLng!
    );

    debugPrint('📏 Total distance calculated: ${dist.toStringAsFixed(1)} km');
    return '${dist.toStringAsFixed(1)} km';
  }

  /// Get estimated delivery time based on distance
  /// ✅ Validation in estimatedDeliveryTime - Checks for 0.0 values
  String get estimatedDeliveryTime {
    if (!hasValidPickupCoordinates || !hasValidDeliveryCoordinates) {
      debugPrint('⚠️ Cannot estimate time: Invalid coordinates');
      return '--';
    }

    final dist = _calculateDistance(
        pickupLat!,
        pickupLng!,
        deliveryLat!,
        deliveryLng!
    );

    final mins = ((dist / 30) * 60).round(); // Assume 30 km/h avg speed
    debugPrint('⏱️ Estimated delivery time: $mins mins');
    return '$mins mins';
  }

  /// Calculate distance using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double deg) => deg * (pi / 180);

  /// Set order details manually (useful when data comes from parent screen)
  /// ✅ Debug in setOrderDetails() - Logs manual coordinate setting
  void setOrderDetails({
    required String status,
    required String custName,
    required String custPhone,
    required String delivAddress,
    required String restaurant,
    required String restaurantAddress,
    required String restaurantPhone,
    required double amount,
    required String payment,
    List<Map<String, dynamic>>? orderItems,
    double? pickLat,
    double? pickLng,
    double? delivLat,
    double? delivLng,
  }) {
    orderStatus = status.isEmpty ? 'accepted' : status;
    customerName = custName;
    customerPhone = custPhone;
    deliveryAddress = delivAddress;
    messName = restaurant;
    messAddress = restaurantAddress;
    messPhone = restaurantPhone;
    orderAmount = amount;
    paymentMethod = payment;
    items = orderItems ?? [];

    // ✅ Use helper for manual coordinate setting
    pickupLat = _parseCoordinate(pickLat);
    pickupLng = _parseCoordinate(pickLng);
    deliveryLat = _parseCoordinate(delivLat);
    deliveryLng = _parseCoordinate(delivLng);

    // ✅ Debug logging for manual coordinate setting
    debugPrint('🔧 Manual order details set:');
    debugPrint('   Status: $orderStatus');
    debugPrint('   Pickup coords: ${pickupLat ?? "null"}, ${pickupLng ?? "null"}');
    debugPrint('   Delivery coords: ${deliveryLat ?? "null"}, ${deliveryLng ?? "null"}');
    debugPrint('   Valid Pickup: $hasValidPickupCoordinates');
    debugPrint('   Valid Delivery: $hasValidDeliveryCoordinates');

    notifyListeners();
  }

  /// Check if order can be marked as reached pickup
  bool canMarkReachedPickup() {
    return orderStatus == 'accepted' ||
        orderStatus == 'confirmed' ||
        orderStatus.isEmpty;
  }

  /// Check if order can be marked as picked up
  bool canMarkPickedUp() {
    return orderStatus == 'ready' ||
        orderStatus == 'at_pickup_location' ||
        orderStatus == 'reached_pickup';
  }

  /// Check if order can be marked as in transit
  bool canMarkInTransit() {
    return orderStatus == 'out_for_delivery' ||
        orderStatus == 'picked_up';
  }

  /// Check if order can be marked as delivered
  bool canMarkDelivered() {
    return orderStatus == 'out_for_delivery' ||
        orderStatus == 'picked_up' ||
        orderStatus == 'in_transit';
  }
}
