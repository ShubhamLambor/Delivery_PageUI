// lib/screens/home/widgets/current_delivery_card.dart

import 'package:flutter/material.dart';
import '../../../models/delivery_model.dart';
import '../../map/osm_navigation_screen.dart';

class CurrentDeliveryCard extends StatelessWidget {
  final DeliveryModel delivery;
  final VoidCallback? onCall;
  final VoidCallback? onPickedUp;
  final VoidCallback? onInTransit;
  final VoidCallback? onDelivered;
  final VoidCallback? onCancel;

  const CurrentDeliveryCard({
    super.key,
    required this.delivery,
    this.onCall,
    this.onPickedUp,
    this.onInTransit,
    this.onDelivered,
    this.onCancel,
  });

  // ✅ FIXED: Proper null checking before navigation
  Future<void> _handleNavigation(BuildContext context) async {
    // Extract coordinates with null safety
    final double? lat = delivery.latitude;
    final double? lng = delivery.longitude;
    final String name = delivery.customerName;

    // ✅ Validate coordinates before navigating
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location coordinates not available. Please contact support.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // ✅ Check if coordinates are valid (not zero)
    if (lat == 0.0 || lng == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid delivery location. Please update the order details.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // ✅ Navigate with validated coordinates
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OSMNavigationScreen(
          destinationLat: lat,
          destinationLng: lng,
          destinationName: name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// --- Header: Order ID + Status Badge ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Order ID & Customer Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ${delivery.id}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      delivery.customerName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Badge
              _buildStatusBadge(delivery.status),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          /// --- Mess/Restaurant Info ---
          _buildInfoRow(
            Icons.restaurant,
            'Mess',
            delivery.item, // This should be mess name from backend
            Colors.orange,
          ),
          const SizedBox(height: 10),

          /// --- Delivery Address ---
          _buildInfoRow(
            Icons.location_on,
            'Delivery Address',
            delivery.address,
            Colors.red,
          ),
          const SizedBox(height: 10),

          /// --- Amount ---
          _buildInfoRow(
            Icons.currency_rupee,
            'Amount',
            '₹${delivery.amount}',
            Colors.green,
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          /// --- Action Buttons Based on Status ---
          _buildActionButtons(context, delivery.status),
        ],
      ),
    );
  }

  /// Build Status Badge
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String displayText;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'accepted':
      case 'pending':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        displayText = 'Accepted';
        icon = Icons.check_circle_outline;
        break;

      case 'confirmed':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        displayText = 'Confirmed';
        icon = Icons.verified_outlined;
        break;

      case 'waiting_for_order':
        bgColor = Colors.amber.shade50;
        textColor = Colors.amber.shade700;
        displayText = 'Waiting for Order';
        icon = Icons.hourglass_empty;
        break;

      case 'waiting_for_pickup':
      case 'ready':
      case 'ready_for_pickup':
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        displayText = 'Ready for Pickup';
        icon = Icons.shopping_bag;
        break;

      case 'picked_up':
      case 'out_for_delivery':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        displayText = 'Picked Up';
        icon = Icons.inventory_2_outlined;
        break;

      case 'in_transit':
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        displayText = 'In Transit';
        icon = Icons.local_shipping_outlined;
        break;

      case 'delivered':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        displayText = 'Delivered';
        icon = Icons.check_circle;
        break;

      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        displayText = status;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Build Info Row
  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build Action Buttons Based on Order Status
  Widget _buildActionButtons(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'confirmed':
      case 'pending':
      case 'waiting_for_order':
      case 'waiting_for_pickup':
      case 'ready':
      case 'ready_for_pickup':
        return _buildAcceptedActions(context);

      case 'picked_up':
      case 'out_for_delivery':
        return _buildPickedUpActions(context);

      case 'in_transit':
        return _buildInTransitActions(context);

      default:
        return const SizedBox.shrink();
    }
  }

  /// Actions when order is "Accepted" (need to pick up)
  Widget _buildAcceptedActions(BuildContext context) {
    return Column(
      children: [
        // Navigate + Call Row
        Row(
          children: [
            // Navigate to Mess Button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _handleNavigation(context),
                icon: const Icon(Icons.navigation, size: 18),
                label: const Text('Navigate to Mess'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Call Button
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: IconButton(
                onPressed: onCall,
                icon: const Icon(Icons.call, color: Colors.green, size: 20),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Mark Picked Up Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onPickedUp,
            icon: const Icon(Icons.inventory_2, size: 20),
            label: const Text('Mark as Picked Up'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Actions when order is "Picked Up" (on the way)
  Widget _buildPickedUpActions(BuildContext context) {
    return Column(
      children: [
        // Navigate + Call Row
        Row(
          children: [
            // Navigate to Customer Button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _handleNavigation(context),
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Navigate to Customer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Call Button
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: IconButton(
                onPressed: onCall,
                icon: const Icon(Icons.call, color: Colors.green, size: 20),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Mark In Transit Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onInTransit,
            icon: const Icon(Icons.local_shipping, size: 20),
            label: const Text('Mark as In Transit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Actions when order is "In Transit" (delivering)
  Widget _buildInTransitActions(BuildContext context) {
    return Column(
      children: [
        // Navigate + Call Row
        Row(
          children: [
            // Navigate to Customer Button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _handleNavigation(context),
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Navigate to Customer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Call Button
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: IconButton(
                onPressed: onCall,
                icon: const Icon(Icons.call, color: Colors.green, size: 20),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Mark Delivered Button (Primary Action)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onDelivered,
            icon: const Icon(Icons.check_circle, size: 22),
            label: const Text('Mark as Delivered'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2FA84F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
