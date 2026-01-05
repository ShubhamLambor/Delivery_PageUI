// lib/screens/home/widgets/current_delivery_card.dart

import 'package:flutter/material.dart';
import '../../../models/delivery_model.dart';
import '../../map/osm_navigation_screen.dart';

class CurrentDeliveryCard extends StatelessWidget {
  final DeliveryModel delivery;
  final VoidCallback? onCall;
  final VoidCallback? onDelivered;
  final VoidCallback? onCancel;

  const CurrentDeliveryCard({
    super.key,
    required this.delivery,
    this.onCall,
    this.onDelivered,
    this.onCancel,
  });

  Future<void> _handleNavigation(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OSMNavigationScreen(
          destinationLat: delivery.latitude,
          destinationLng: delivery.longitude,
          destinationName: delivery.customerName,
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
          // Header Row (Name + Explicit Navigate Button)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  delivery.customerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // --- CHANGED: Explicit Navigate Button ---
              InkWell(
                onTap: () => _handleNavigation(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.near_me, color: Colors.blue, size: 16), // Use "near_me" or "navigation"
                      SizedBox(width: 4),
                      Text(
                        "Map",
                        style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Address Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  delivery.address,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Details Row (ETA + Item)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _detailItem(Icons.access_time, 'ETA: ${delivery.eta}', Colors.orange),
                Container(width: 1, height: 16, color: Colors.grey.shade300), // Divider
                _detailItem(Icons.inventory_2_outlined, delivery.item, Colors.green),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Action Buttons Row (Combined)
          Row(
            children: [
              // Call Button (Small)
              InkWell(
                onTap: onCall,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.call, color: Colors.green, size: 20),
                ),
              ),
              const SizedBox(width: 10),

              // Slide-to-complete style Button (Primary)
              Expanded(
                child: _primaryButton(
                  label: 'Mark Delivered',
                  color: const Color(0xFF2FA84F),
                  icon: Icons.check_circle_outline,
                  onTap: onDelivered,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800]),
        ),
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
