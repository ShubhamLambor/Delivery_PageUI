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

  // ✅ PRESERVED: Dynamic Navigation Logic (Mess vs Customer)
  Future<void> _handleNavigation(BuildContext context) async {
    double? targetLat;
    double? targetLng;
    String targetName;

    final status = delivery.status.toLowerCase().trim();

    // 1️⃣ Determine Destination based on Order Status
    final isPickupPhase = [
      'accepted',
      'confirmed',
      'pending',
      'waiting_for_order',
      'waiting_for_pickup',
      'ready',
      'ready_for_pickup',
      'at_pickup_location',
      'reached_pickup'
    ].contains(status);

    if (isPickupPhase) {
      // 📍 GO TO MESS
      targetLat = delivery.pickupLatitude;
      targetLng = delivery.pickupLongitude;
      targetName = "Mess: ${delivery.messName ?? delivery.item}";
    } else {
      // 📍 GO TO CUSTOMER
      targetLat = delivery.latitude;
      targetLng = delivery.longitude;
      targetName = "Customer: ${delivery.customerName}";
    }

    // 2️⃣ Validation
    if (targetLat == null || targetLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPickupPhase
              ? 'Mess location not available.'
              : 'Customer location not available.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (targetLat == 0.0 || targetLng == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid location coordinates. Please contact support.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 3️⃣ Navigate
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OSMNavigationScreen(
          destinationLat: targetLat!,
          destinationLng: targetLng!,
          destinationName: targetName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Matches your app's rounded look
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- HEADER Section (Green Top) ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${delivery.orderId}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32), // Deep Green
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      delivery.time.split(' ').last, // Simple time display
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                _buildStatusChip(delivery.displayStatus),
              ],
            ),
          ),

          // --- BODY Section (Timeline) ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 📍 PICKUP (Mess)
                _buildLocationRow(
                  icon: Icons.store_mall_directory,
                  iconColor: Colors.orange,
                  title: delivery.messName ?? delivery.item,
                  subtitle: delivery.messAddress ?? "Mess Location",
                  isLast: false,
                ),

                // 📍 DROP (Customer)
                _buildLocationRow(
                  icon: Icons.person_pin_circle,
                  iconColor: Colors.green,
                  title: delivery.customerName,
                  subtitle: delivery.address,
                  isLast: true,
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 16),

                // 💰 PAYMENT INFO
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.payment,
                              size: 16,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              delivery.paymentMethod?.toUpperCase() ?? 'CASH',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${delivery.totalAmount ?? delivery.amount}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32), // Green Amount
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // --- ACTION BUTTONS ---
                _buildActionButtons(context, delivery.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildStatusChip(String status) {
    Color bg;
    Color text;

    switch (status.toLowerCase()) {
      case 'new':
      case 'assigned':
        bg = Colors.blue.shade50;
        text = Colors.blue.shade700;
        break;
      case 'picked up':
        bg = Colors.orange.shade50;
        text = Colors.orange.shade800;
        break;
      case 'delivered':
        bg = Colors.green.shade50;
        text = Colors.green.shade700;
        break;
      default: // Accepted, etc.
        bg = const Color(0xFFE8F5E9); // Green 50
        text = const Color(0xFF2E7D32); // Green 800
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Column
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Text Column
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6), // Align with icon
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String status) {
    final s = status.toLowerCase().trim();

    // 1. MESS PHASE
    if (['accepted', 'confirmed', 'pending', 'waiting_for_order', 'waiting_for_pickup', 'ready', 'ready_for_pickup'].contains(s)) {
      return _buildPhaseActions(
        context,
        navLabel: 'Navigate to Mess',
        navIcon: Icons.near_me,
        navColor: const Color(0xFF1E88E5), // Blue for navigation
        actionLabel: 'Mark Picked Up',
        actionIcon: Icons.inventory_2,
        actionColor: const Color(0xFFEF6C00), // Orange for action
        onAction: onPickedUp,
      );
    }

    // 2. CUSTOMER PHASE
    if (['picked_up', 'out_for_delivery', 'in_transit'].contains(s)) {
      final isTransit = s == 'in_transit';
      return _buildPhaseActions(
        context,
        navLabel: 'Navigate to Customer',
        navIcon: Icons.navigation,
        navColor: const Color(0xFF2E7D32), // Green for navigation
        actionLabel: isTransit ? 'Mark Delivered' : 'Start Delivery',
        actionIcon: isTransit ? Icons.check_circle : Icons.local_shipping,
        actionColor: isTransit ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00),
        onAction: isTransit ? onDelivered : onInTransit,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPhaseActions(
      BuildContext context, {
        required String navLabel,
        required IconData navIcon,
        required Color navColor,
        required String actionLabel,
        required IconData actionIcon,
        required Color actionColor,
        required VoidCallback? onAction,
      }) {
    return Column(
      children: [
        Row(
          children: [
            // Navigate Button (Expanded)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handleNavigation(context),
                icon: Icon(navIcon, size: 18),
                label: Text(navLabel),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: navColor.withOpacity(0.1),
                  foregroundColor: navColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Call Button (Square)
            Container(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: onCall,
                icon: const Icon(Icons.call, color: Colors.green),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Primary Action Button (Full Width, Solid)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onAction,
            icon: Icon(actionIcon, size: 20),
            label: Text(
              actionLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 4,
              shadowColor: actionColor.withOpacity(0.4),
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}