// lib/widgets/delivery/order_status_stepper.dart
import 'package:flutter/material.dart';

class OrderStatusStepper extends StatelessWidget {
  final String status;
  final String assignmentStatus;

  const OrderStatusStepper({
    super.key,
    required this.status,
    required this.assignmentStatus,
  });

  int get _currentStep {
    final s = status.toLowerCase();
    final a = assignmentStatus.toLowerCase();

    if (s == 'delivered') return 3;
    // ✅ FIXED: Added underscores to match backend ('outfordelivery' -> 'out_for_delivery', 'pickedup' -> 'picked_up')
    if (s == 'out_for_delivery' || a == 'picked_up' || a == 'in_transit') return 2;
    // ✅ FIXED: Added underscore ('atpickup' -> 'at_pickup')
    if (a == 'at_pickup' || a == 'at_pickup_location') return 1;

    return 0; // confirmed / accepted
  }

  @override
  Widget build(BuildContext context) {
    final step = _currentStep;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildDot(context, 0, step, 'Accepted'),
          _buildDivider(),
          _buildDot(context, 1, step, 'At pickup'),
          _buildDivider(),
          _buildDot(context, 2, step, 'On the way'),
          _buildDivider(),
          _buildDot(context, 3, step, 'Delivered'),
        ],
      ),
    );
  }

  Widget _buildDot(BuildContext context, int index, int current, String label) {
    final active = index <= current;
    final color = active ? Colors.green : Colors.grey.shade400;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: color,
          child: Icon(
            active ? Icons.check : Icons.circle,
            size: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Expanded(
      child: Container(
        height: 2,
        color: Colors.grey.shade300,
      ),
    );
  }
}
