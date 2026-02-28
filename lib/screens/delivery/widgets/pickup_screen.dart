// lib/screens/delivery/pickup_screen.dart
import 'package:flutter/material.dart';
import '../../../models/delivery_model.dart';

class PickupScreen extends StatelessWidget {
  final DeliveryModel order;
  final bool isUpdating;
  // Kept for API compatibility, but we won't call it here
  final Future<void> Function() onReachedPickup;
  final Future<void> Function() onPickedUp;
  final VoidCallback onNavigateToMess;

  const PickupScreen({
    super.key,
    required this.order,
    required this.isUpdating,
    required this.onReachedPickup,
    required this.onPickedUp,
    required this.onNavigateToMess,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.messName ?? 'Pickup location',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            order.messAddress ?? '',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text(
            'You have reached the pickup. Mark the order as picked up once food is collected.',
            style: TextStyle(fontSize: 14),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isUpdating ? null : onNavigateToMess,
              icon: const Icon(Icons.navigation),
              label: const Text('Navigate to Mess'),
            ),
          ),
          const SizedBox(height: 12),
          // Only allow "Order Picked Up" from this screen
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: isUpdating
                  ? null
                  : () async {
                await onPickedUp();
              },
              child: isUpdating
                  ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text('Order Picked Up'),
            ),
          ),
        ],
      ),
    );
  }
}
