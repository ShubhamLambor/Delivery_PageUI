// lib/screens/delivery/order_tracking_controller.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../services/delivery_service.dart';

class OrderTrackingController extends ChangeNotifier {
  final String orderId;
  final String deliveryPartnerId;

  OrderTrackingController({
    required this.orderId,
    required this.deliveryPartnerId,
  });

  // State
  bool isLoading = false;
  String orderStatus = 'accepted'; // Default fallback

  // Order Details
  String customerId = '';
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

  /// Helper method for robust coordinate parsing
  double? _parseCoordinate(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;
    if (value is int) return value.toDouble();

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return double.tryParse(trimmed);
    }

    return null;
  }

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

  /// Load order details using DeliveryService
  Future<void> loadOrderDetails(String orderId) async {
    isLoading = true;
    notifyListeners();

    try {
      debugPrint('📋 Loading order details for: $orderId');

      final result = await DeliveryService.getOrderDetails(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
      );

      if (result['success'] == true && result['order'] != null) {
        final order = result['order'];

        // Status
        final rawStatus = order['status'];
        if (rawStatus == null || rawStatus.toString().trim().isEmpty) {
          orderStatus = 'accepted';
          debugPrint('⚠️ Order status was empty, defaulting to "accepted"');
        } else {
          orderStatus = rawStatus.toString();
        }

        // Details
        customerId = order['customer_id']?.toString() ?? '';
        customerName = order['customer_name'] ?? '';
        customerPhone = order['customer_phone'] ?? '';
        deliveryAddress = order['delivery_address'] ?? '';
        messName = order['mess_name'] ?? '';
        messAddress = order['mess_address'] ?? '';
        messPhone = order['mess_phone'] ?? '';
        orderAmount =
            double.tryParse(order['total_amount'].toString()) ?? 0.0;
        deliveryFee =
            double.tryParse(order['delivery_fee'].toString()) ?? 0.0;
        paymentMethod = order['payment_method'] ?? '';

        // Coordinates
        pickupLat = _parseCoordinate(order['pickup_latitude']);
        pickupLng = _parseCoordinate(order['pickup_longitude']);
        deliveryLat = _parseCoordinate(order['delivery_latitude']);
        deliveryLng = _parseCoordinate(order['delivery_longitude']);

        if (!hasValidDeliveryCoordinates) {
          debugPrint(
              '⚠️ Delivery coordinates missing, checking customer_address...');
          deliveryLat = _parseCoordinate(order['customer_latitude']) ??
              _parseCoordinate(order['customer_address_latitude']);
          deliveryLng = _parseCoordinate(order['customer_longitude']) ??
              _parseCoordinate(order['customer_address_longitude']);
        }

        debugPrint('📍 Coordinates parsed:');
        debugPrint('   Pickup: ${pickupLat ?? "null"}, ${pickupLng ?? "null"}');
        debugPrint(
            '   Delivery: ${deliveryLat ?? "null"}, ${deliveryLng ?? "null"}');
        debugPrint('   Valid Pickup: $hasValidPickupCoordinates');
        debugPrint('   Valid Delivery: $hasValidDeliveryCoordinates');

        // Items
        if (order['items'] != null && order['items'] is List) {
          items = (order['items'] as List)
              .map<Map<String, dynamic>>((item) => {
            'name': item['item_name'],
            'quantity': item['quantity'],
            'price': item['price'],
            'subtotal': item['subtotal'],
          })
              .toList();
        }

        // Timestamps
        if (order['accepted_at'] != null) {
          acceptedAt = DateTime.tryParse(order['accepted_at']);
        }
        if (order['reached_pickup_at'] != null) {
          reachedPickupAt =
              DateTime.tryParse(order['reached_pickup_at']);
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
        debugPrint(
            '❌ Failed to load order: ${result['message'] ?? "Unknown error"}');
      }
    } catch (e) {
      debugPrint('❌ Error loading order: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> markReachedPickup() async {
    try {
      debugPrint('📍 Marking reached pickup for order: $orderId...');

      final result = await DeliveryService.markReachedPickup(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
      );

      if (result['success'] == true) {
        if (result['status'] != null &&
            result['status'].toString().isNotEmpty) {
          orderStatus = result['status'].toString();
        } else {
          orderStatus = 'assigned_to_delivery';
        }

        reachedPickupAt = DateTime.now();

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

  Future<bool> markPickedUp() async {
    try {
      debugPrint('📦 Marking order $orderId as picked up...');

      final result = await DeliveryService.markPickedUp(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
      );

      if (result['success'] == true) {
        if (result['status'] != null &&
            result['status'].toString().isNotEmpty) {
          orderStatus = result['status'].toString();
        } else {
          orderStatus = 'out_for_delivery';
        }

        pickedUpAt = DateTime.now();

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

  /// Step 1: call OTP API – hits generate_delivery_otp.php
  Future<Map<String, dynamic>> startOtpDelivery() async {
    try {
      debugPrint('🔐 Generating delivery OTP for order $orderId...');

      final result = await DeliveryService.generateDeliveryOtp(
        orderId: orderId,
        customerId: customerId,
      );

      if (result['success'] == true) {
        debugPrint('✅ OTP generated and sent to customer');
      } else {
        debugPrint('❌ Failed to generate OTP: ${result['message']}');
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error generating delivery OTP: $e');
      return {
        'success': false,
        'message': 'Error generating delivery OTP',
      };
    }
  }

  /// Step 2: mark delivered AFTER OTP verification on backend
  Future<bool> markDeliveredAfterOtp() async {
    try {
      debugPrint('🎉 Marking order $orderId as delivered (after OTP)...');

      final result = await DeliveryService.markDelivered(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
        notes: 'Delivered successfully (OTP verified)',
      );

      if (result['success'] == true) {
        orderStatus = 'delivered';
        deliveredAt = DateTime.now();
        notifyListeners();
        debugPrint('✅ Order marked as delivered successfully (OTP verified)');
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

  /// Backward‑compatible wrapper used by old UI calls
  Future<bool> markDelivered() async {
    // New UI should use: startOtpDelivery -> verify OTP -> markDeliveredAfterOtp
    return markDeliveredAfterOtp();
  }

  String get totalDistance {
    if (!hasValidPickupCoordinates || !hasValidDeliveryCoordinates) {
      debugPrint('⚠️ Cannot calculate distance: Invalid coordinates');
      return '--';
    }

    final dist = _calculateDistance(
      pickupLat!,
      pickupLng!,
      deliveryLat!,
      deliveryLng!,
    );

    debugPrint('📏 Total distance calculated: ${dist.toStringAsFixed(1)} km');
    return '${dist.toStringAsFixed(1)} km';
  }

  String get estimatedDeliveryTime {
    if (!hasValidPickupCoordinates || !hasValidDeliveryCoordinates) {
      debugPrint('⚠️ Cannot estimate time: Invalid coordinates');
      return '--';
    }

    final dist = _calculateDistance(
      pickupLat!,
      pickupLng!,
      deliveryLat!,
      deliveryLng!,
    );

    final mins = ((dist / 30) * 60).round(); // 30 km/h
    debugPrint('⏱️ Estimated delivery time: $mins mins');
    return '$mins mins';
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double deg) => deg * (pi / 180);

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

    pickupLat = _parseCoordinate(pickLat);
    pickupLng = _parseCoordinate(pickLng);
    deliveryLat = _parseCoordinate(delivLat);
    deliveryLng = _parseCoordinate(delivLng);

    debugPrint('🔧 Manual order details set:');
    debugPrint('   Status: $orderStatus');
    debugPrint(
        '   Pickup coords: ${pickupLat ?? "null"}, ${pickupLng ?? "null"}');
    debugPrint(
        '   Delivery coords: ${deliveryLat ?? "null"}, ${deliveryLng ?? "null"}');
    debugPrint('   Valid Pickup: $hasValidPickupCoordinates');
    debugPrint('   Valid Delivery: $hasValidDeliveryCoordinates');

    notifyListeners();
  }

  bool canMarkReachedPickup() {
    return orderStatus == 'accepted' ||
        orderStatus == 'confirmed' ||
        orderStatus == 'assigned' ||
        orderStatus.isEmpty;
  }

  bool canMarkPickedUp() {
    return orderStatus == 'ready' ||
        orderStatus == 'ready_for_pickup' ||
        orderStatus == 'readyforpickup';
  }

  bool canMarkInTransit() {
    return orderStatus == 'out_for_delivery' || orderStatus == 'picked_up';
  }

  bool canMarkDelivered() {
    return orderStatus == 'out_for_delivery' ||
        orderStatus == 'picked_up' ||
        orderStatus == 'in_transit';
  }
}
