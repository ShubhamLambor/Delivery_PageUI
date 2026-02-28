// lib/screens/delivery/waiting_for_order_screen.dart
import 'package:flutter/material.dart';
import '../../../models/delivery_model.dart';

class WaitingForOrderScreen extends StatelessWidget {
  final DeliveryModel order;
  final bool isUpdating;
  final VoidCallback onNavigateToMess;
  final Future<void> Function() onReachedPickup;

  const WaitingForOrderScreen({
    super.key,
    required this.order,
    required this.isUpdating,
    required this.onNavigateToMess,
    required this.onReachedPickup,
  });

  bool get _canReachPickup {
    final s = order.status.toLowerCase();
    final a = order.assignmentStatus.toLowerCase();
    return (s == 'confirmed' || s == 'ready') &&
        (a == 'accepted' || a == 'assigned'); // ✅ Now allows 'ready' state
  }

  @override
  Widget build(BuildContext context) {
    final canReachPickup = _canReachPickup;

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
          Text(
            canReachPickup
                ? 'Navigate to pickup, then tap when you reach the kitchen.'
                : 'Pickup already marked. Waiting for next step.',
            style: const TextStyle(fontSize: 14),
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
          if (canReachPickup) // 🔑 only show button when allowed
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () async {
                  if (!_canReachPickup) return; // double-check guard
                  await onReachedPickup();       // calls reached_pickup once
                },
                child: isUpdating
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Reached Pickup'),
              ),
            ),
        ],
      ),
    );
  }
}
