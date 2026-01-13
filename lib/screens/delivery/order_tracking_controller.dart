// lib/screens/delivery/order_tracking_controller.dart

import 'package:flutter/material.dart';
import '../../services/delivery_service.dart';

class OrderTrackingController extends ChangeNotifier {
  final String orderId;
  final String deliveryPartnerId;

  // Base URL for API
  static const String baseUrl = 'https://svtechshant.com/tiffin/api';

  OrderTrackingController({
    required this.orderId,
    required this.deliveryPartnerId,
  });

  bool isLoading = false;
  String orderStatus = 'accepted'; // accepted, reached_pickup, picked_up, in_transit, delivered

  // Order Details
  String customerName = '';
  String customerPhone = '';
  String deliveryAddress = '';
  String messName = '';
  String messAddress = '';
  String messPhone = '';
  double orderAmount = 0.0;
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

  /// Load order details from backend
  /// Note: This requires get_order_details.php endpoint to be created
  Future<void> loadOrderDetails(String orderId) async {
    isLoading = true;
    notifyListeners();

    try {
      debugPrint('📋 Loading order details for: $orderId');

      // TODO: Implement get_order_details.php endpoint on backend
      // For now, order details come from the active orders list
      // This method can be enhanced later when the endpoint is ready

      debugPrint('⚠️ get_order_details.php endpoint not implemented yet');
      debugPrint('   Using order data from active orders list');

    } catch (e) {
      debugPrint('❌ Error loading order: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  /// Mark as reached pickup location
  Future<bool> markReachedPickup() async {
    try {
      debugPrint('📍 Marking reached pickup for order $orderId...');

      final result = await DeliveryService.markReachedPickup(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
      );

      if (result['success'] == true) {
        orderStatus = 'reached_pickup';
        reachedPickupAt = DateTime.now();
        notifyListeners();
        debugPrint('✅ Marked as reached pickup successfully');
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

      // Use DeliveryService which calls order_delivery_status.php
      final result = await DeliveryService.markPickedUp(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
      );

      if (result['success'] == true) {
        orderStatus = 'picked_up';
        pickedUpAt = DateTime.now();
        notifyListeners();
        debugPrint('✅ Order marked as picked up successfully');
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
      debugPrint('🚚 Marking order $orderId as in transit...');

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
      debugPrint('✅ Marking order $orderId as delivered...');

      // Use DeliveryService which calls order_delivery_status.php
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

  /// Get estimated delivery time based on distance
  String get estimatedDeliveryTime {
    // Calculate based on distance or return default
    // TODO: Implement actual calculation based on pickup/delivery locations
    return '25-30 mins';
  }

  /// Get total distance between pickup and delivery points
  double get totalDistance {
    // Calculate distance between pickup and delivery
    // TODO: Implement haversine formula or use Google Distance Matrix API
    // For now, return dummy value
    return 5.2; // km
  }

  /// Set order details manually (useful when data comes from parent screen)
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
    orderStatus = status;
    customerName = custName;
    customerPhone = custPhone;
    deliveryAddress = delivAddress;
    messName = restaurant;
    messAddress = restaurantAddress;
    messPhone = restaurantPhone;
    orderAmount = amount;
    paymentMethod = payment;
    items = orderItems ?? [];
    pickupLat = pickLat;
    pickupLng = pickLng;
    deliveryLat = delivLat;
    deliveryLng = delivLng;
    notifyListeners();
  }

  /// Check if order can be marked as reached pickup
  bool canMarkReachedPickup() {
    return orderStatus == 'accepted';
  }

  /// Check if order can be marked as picked up
  bool canMarkPickedUp() {
    return orderStatus == 'accepted' || orderStatus == 'reached_pickup';
  }

  /// Check if order can be marked as in transit
  bool canMarkInTransit() {
    return orderStatus == 'picked_up';
  }

  /// Check if order can be marked as delivered
  bool canMarkDelivered() {
    return orderStatus == 'picked_up' || orderStatus == 'in_transit';
  }
}
