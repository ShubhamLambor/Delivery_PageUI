import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../map/osm_navigation_screen.dart';
import '../order_tracking_controller.dart';
import '../../../services/delivery_service.dart';

class NavigationScreen extends StatelessWidget {
  final OrderTrackingController controller;

  const NavigationScreen({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.delivery_dining, color: Colors.white, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Delivering to',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.customerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetric(controller.totalDistance, 'km', 'Distance'),
              Container(width: 1, height: 30, color: Colors.grey.shade300),
              _buildMetric(controller.estimatedDeliveryTime, '', 'ETA'),
            ],
          ),
          const SizedBox(height: 24),

          // Customer Details
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on, color: Colors.red),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Delivery Location',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.person, controller.customerName),
                _buildInfoRow(Icons.location_city, controller.deliveryAddress),
                _buildInfoRow(Icons.phone, controller.customerPhone),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _callCustomer(controller.customerPhone),
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text('Call Customer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openOSMNavigation(
                          context,
                          controller.deliveryLat,
                          controller.deliveryLng,
                          controller.customerName,
                        ),
                        icon: const Icon(Icons.navigation, size: 18),
                        label: const Text('Navigate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Mark Delivered Button (with OTP)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _markDelivered(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Mark as Delivered',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String value, String unit, String label) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E88E5),
              ),
            ),
            if (unit.isNotEmpty)
              Text(
                ' $unit',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Future<void> _callCustomer(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openOSMNavigation(
      BuildContext context,
      double? lat,
      double? lng,
      String destinationName,
      ) {
    if (lat == null || lng == null || lat == 0.0 || lng == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OSMNavigationScreen(
          destinationLat: lat,
          destinationLng: lng,
          destinationName: destinationName,
        ),
      ),
    );
  }

  Future<void> _markDelivered(BuildContext context) async {
    // Step 0: Confirm they really want to complete delivery
    final confirmStart = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start OTP Verification'),
        content: const Text(
          'We will send an OTP to the customer. Ask them to share it with you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Send OTP'),
          ),
        ],
      ),
    );

    if (confirmStart != true) return;

    // Step 1: Generate OTP (backend sends SMS)
    final otpResult = await controller.startOtpDelivery();
    if (otpResult['success'] != true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(otpResult['message'] ?? 'Failed to generate OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Step 2: Ask partner to enter OTP received by customer
    final otp = await showDialog<String>(
      context: context,
      builder: (context) {
        final TextEditingController otpController = TextEditingController();
        return AlertDialog(
          title: const Text('Enter OTP'),
          content: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '6-digit OTP',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, otpController.text.trim()),
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );

    if (otp == null || otp.isEmpty) return;

    // Step 3: Verify OTP with backend
    final verifyResult = await DeliveryService.verifyDeliveryOtp(
      orderId: controller.orderId,
      otp: otp,
    );

    if (verifyResult['success'] != true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(verifyResult['message'] ?? 'Invalid OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Step 4: Mark as delivered (after OTP)
    final success = await controller.markDeliveredAfterOtp();
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order delivered successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
