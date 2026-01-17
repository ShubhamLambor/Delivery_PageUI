import 'package:flutter/material.dart';

class OrderStatusStepper extends StatelessWidget {
  final String currentStatus;

  const OrderStatusStepper({
    Key? key,
    required this.currentStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final steps = ['Accepted', 'Picked Up', 'Delivered'];
    final statuses = ['accepted', 'picked_up', 'delivered'];
    final currentIndex = statuses.indexOf(currentStatus.toLowerCase());

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
                // ✅ FIXED: Step Circle with proper constraints
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // ✅ Added
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
                      // ✅ FIXED: Text with proper overflow handling
                      Text(
                        steps[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? Colors.green : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1, // ✅ Limit to 1 line
                        overflow: TextOverflow.ellipsis, // ✅ Add ellipsis for long text
                      ),
                    ],
                  ),
                ),

                // ✅ FIXED: Connector Line with proper sizing
                if (!isLast)
                  Flexible( // ✅ Changed from Expanded to Flexible
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 24, left: 4, right: 4), // ✅ Added horizontal margin
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
