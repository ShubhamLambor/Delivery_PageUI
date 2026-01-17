import 'package:flutter/material.dart';
import '../order_tracking_controller.dart';

class DeliveryConfirmationScreen extends StatelessWidget {
  final OrderTrackingController controller;

  const DeliveryConfirmationScreen({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ CRITICAL FIX: Wrap Column in SingleChildScrollView to prevent overflow
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success Animation
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 120,
            ),
          ),
          const SizedBox(height: 32),

          const Text(
            'Delivery Completed!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),

          // ✅ FIXED: Wrapped text with proper constraints
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Order delivered successfully to ${controller.customerName}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              maxLines: 2, // ✅ Limit lines
              overflow: TextOverflow.ellipsis, // ✅ Handle overflow
            ),
          ),
          const SizedBox(height: 32),

          // Earnings Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'You Earned',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${(controller.orderAmount * 0.1).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Delivery Fee',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat('Distance', '${controller.totalDistance}'),
              _buildStat('Time', '25 mins'),
              _buildStat('Rating', '⭐ 5.0'),
            ],
          ),

          // ✅ FIXED: Add spacing instead of Spacer (Spacer doesn't work in ScrollView)
          const SizedBox(height: 40),

          // Done Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Back to Home',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // ✅ Added bottom padding for safe area
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Flexible( // ✅ Changed from implicit sizing to Flexible
      child: Column(
        mainAxisSize: MainAxisSize.min, // ✅ Added
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1, // ✅ Prevent overflow
            overflow: TextOverflow.ellipsis, // ✅ Handle overflow
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 1, // ✅ Prevent overflow
            overflow: TextOverflow.ellipsis, // ✅ Handle overflow
          ),
        ],
      ),
    );
  }
}
