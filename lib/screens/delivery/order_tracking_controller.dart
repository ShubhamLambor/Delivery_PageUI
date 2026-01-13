import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderTrackingController extends ChangeNotifier {
  final String orderId;
  final String deliveryPartnerId;

  OrderTrackingController({
    required this.orderId,
    required this.deliveryPartnerId,
  });

  bool isLoading = false;
  String orderStatus = 'accepted'; // accepted, picked_up, delivered

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
  DateTime? pickedUpAt;
  DateTime? deliveredAt;

  Future<void> loadOrderDetails(String orderId) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('YOUR_API_URL/get_order_details.php'),
        body: {
          'order_id': orderId,
          'delivery_partner_id': deliveryPartnerId,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final order = data['order'];

          orderStatus = order['status'] ?? 'accepted';
          customerName = order['customer_name'] ?? '';
          customerPhone = order['customer_phone'] ?? '';
          deliveryAddress = order['delivery_address'] ?? '';
          messName = order['mess_name'] ?? '';
          messAddress = order['mess_address'] ?? '';
          messPhone = order['mess_phone'] ?? '';
          orderAmount = double.tryParse(order['total_amount'].toString()) ?? 0.0;
          paymentMethod = order['payment_method'] ?? '';
          items = List<Map<String, dynamic>>.from(order['items'] ?? []);

          pickupLat = double.tryParse(order['pickup_lat']?.toString() ?? '');
          pickupLng = double.tryParse(order['pickup_lng']?.toString() ?? '');
          deliveryLat = double.tryParse(order['delivery_lat']?.toString() ?? '');
          deliveryLng = double.tryParse(order['delivery_lng']?.toString() ?? '');

          print('✅ Order details loaded: Status = $orderStatus');
        }
      }
    } catch (e) {
      print('❌ Error loading order: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> markPickedUp() async {
    try {
      final response = await http.post(
        Uri.parse('YOUR_API_URL/update_order_status.php'),
        body: {
          'action': 'picked_up',
          'order_id': orderId,
          'delivery_partner_id': deliveryPartnerId,
        },
      );

      final data = json.decode(response.body);
      if (data['success']) {
        orderStatus = 'picked_up';
        pickedUpAt = DateTime.now();
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('❌ Error marking picked up: $e');
    }
    return false;
  }

  Future<bool> markDelivered() async {
    try {
      final response = await http.post(
        Uri.parse('YOUR_API_URL/update_order_status.php'),
        body: {
          'action': 'delivered',
          'order_id': orderId,
          'delivery_partner_id': deliveryPartnerId,
        },
      );

      final data = json.decode(response.body);
      if (data['success']) {
        orderStatus = 'delivered';
        deliveredAt = DateTime.now();
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('❌ Error marking delivered: $e');
    }
    return false;
  }

  String get estimatedDeliveryTime {
    // Calculate based on distance or return default
    return '25-30 mins';
  }

  double get totalDistance {
    // Calculate distance between pickup and delivery
    // For now, return dummy value
    return 5.2; // km
  }
}
