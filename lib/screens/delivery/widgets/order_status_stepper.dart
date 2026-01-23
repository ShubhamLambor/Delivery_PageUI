import 'package:flutter/material.dart';

class OrderStatusStepper extends StatelessWidget {
  final String currentStatus;

  const OrderStatusStepper({
    Key? key,
    required this.currentStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ Updated to 4 steps
    final steps = ['Accepted', 'Ready', 'Picked Up', 'Delivered'];
    final statuses = ['accepted', 'ready', 'picked_up', 'delivered'];

    final status = currentStatus.toLowerCase().trim();

    // ✅ Map various statuses to step indices
    int currentIndex = 0;
    if (status == 'accepted' || status == 'confirmed' || status == 'waiting_for_order' || status.isEmpty) {
      currentIndex = 0;
    } else if (status == 'ready' || status == 'ready_for_pickup' || status == 'reached_pickup' || status == 'at_pickup_location') {
      currentIndex = 1;
    } else if (status == 'picked_up' || status == 'out_for_delivery' || status == 'in_transit') {
      currentIndex = 2;
    } else if (status == 'delivered') {
      currentIndex = 3;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index <= currentIndex;
          final isLast = index == steps.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? Colors.green : Colors.grey[300],
                          border: Border.all(
                            color: isActive ? Colors.green : Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isActive ? Icons.check : Icons.circle,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? Colors.green : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Flexible(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 24, left: 4, right: 4),
                      color: isActive ? Colors.green : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
