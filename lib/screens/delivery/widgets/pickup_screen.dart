import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:url_launcher/url_launcher.dart';
import '../order_tracking_controller.dart';

class PickupScreen extends StatefulWidget {
  final OrderTrackingController controller;

  const PickupScreen({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== Header ====================
              _buildHeader(),
              const SizedBox(height: 24),

              // ==================== Mess Details Card ====================
              _buildInfoCard(
                title: 'Pickup Location',
                icon: Icons.location_on,
                iconColor: Colors.orange,
                children: [
                  _buildInfoRow(Icons.store, widget.controller.messName),
                  _buildInfoRow(Icons.location_city, widget.controller.messAddress),
                  _buildInfoRow(Icons.phone, widget.controller.messPhone),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _callMess(widget.controller.messPhone),
                          icon: const Icon(Icons.call, size: 18),
                          label: const Text('Call Mess'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openMaps(
                            widget.controller.pickupLat,
                            widget.controller.pickupLng,
                          ),
                          icon: const Icon(Icons.navigation, size: 18),
                          label: const Text('Navigate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================== Order Items Card ====================
              _buildInfoCard(
                title: 'Order Items',
                icon: Icons.shopping_bag,
                iconColor: Colors.purple,
                children: [
                  ...widget.controller.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['name'] ?? '',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          Text(
                            'x${item['quantity']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '₹${widget.controller.orderAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.controller.paymentMethod == 'cod'
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.controller.paymentMethod == 'cod'
                              ? Icons.money
                              : Icons.payment,
                          size: 16,
                          color: widget.controller.paymentMethod == 'cod'
                              ? Colors.orange
                              : Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.controller.paymentMethod == 'cod'
                              ? 'Cash on Delivery'
                              : 'Paid Online',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: widget.controller.paymentMethod == 'cod'
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================== Delivery Address ====================
              _buildInfoCard(
                title: 'Delivery Address',
                icon: Icons.home,
                iconColor: Colors.red,
                children: [
                  _buildInfoRow(Icons.person, widget.controller.customerName),
                  _buildInfoRow(Icons.location_on, widget.controller.deliveryAddress),
                  _buildInfoRow(Icons.phone, widget.controller.customerPhone),
                ],
              ),

              const SizedBox(height: 24),

              // ==================== ACTION SLIDERS - STEP BY STEP ====================
              _buildActionSliders(),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== BUILD ACTION SLIDERS ====================
  Widget _buildActionSliders() {
    final status = widget.controller.orderStatus.toLowerCase();

    // Step 1: If status is 'accepted' or 'confirmed' -> Show "Reached Pickup" slider
    if (status == 'accepted' || status == 'confirmed') {
      return Column(
        children: [
          _buildStepIndicator('Step 1 of 3', 'Mark when you reach the mess'),
          const SizedBox(height: 12),
          SlideAction(
            key: const ValueKey('reached_pickup_slider'),
            text: 'Swipe to Mark Reached Pickup',
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            innerColor: Colors.white,
            outerColor: Colors.orange,
            sliderButtonIcon: const Icon(
              Icons.location_on,
              color: Colors.orange,
            ),
            onSubmit: () async {
              await _markReachedPickup(context);
              return null;
            },
          ),
        ],
      );
    }

    // Step 2: If status is 'ready' or 'at_pickup_location' -> Show "Mark Picked Up" slider
    if (status == 'ready' ||
        status == 'at_pickup_location' ||
        status == 'atpickuplocation' ||
        status == 'reached_pickup' ||
        status == 'reachedpickup') {
      return Column(
        children: [
          _buildStepIndicator('Step 2 of 3', 'Collect the order from mess'),
          const SizedBox(height: 12),
          SlideAction(
            key: const ValueKey('picked_up_slider'),
            text: 'Swipe to Mark Order Picked Up',
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            innerColor: Colors.white,
            outerColor: Colors.green,
            sliderButtonIcon: const Icon(
              Icons.shopping_bag,
              color: Colors.green,
            ),
            onSubmit: () async {
              await _markPickedUp(context);
              return null;
            },
          ),
        ],
      );
    }

    // Step 3: If status is 'out_for_delivery' or 'pickedup' -> Show "Mark Delivered" slider
    if (status == 'out_for_delivery' ||
        status == 'outfordelivery' ||
        status == 'picked_up' ||
        status == 'pickedup' ||
        status == 'in_transit' ||
        status == 'intransit') {
      return Column(
        children: [
          _buildStepIndicator('Step 3 of 3', 'Deliver to customer'),
          const SizedBox(height: 12),
          SlideAction(
            key: const ValueKey('delivered_slider'),
            text: 'Swipe to Mark Delivered',
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            innerColor: Colors.white,
            outerColor: const Color(0xFF2FA84F),
            sliderButtonIcon: const Icon(
              Icons.check_circle,
              color: Color(0xFF2FA84F),
            ),
            onSubmit: () async {
              await _markDelivered(context);
              return null;
            },
          ),
        ],
      );
    }

    // If delivered
    if (status == 'delivered') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text(
              '✅ Order Delivered Successfully',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      );
    }

    // Default: Unknown status
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: Colors.grey, size: 32),
          const SizedBox(height: 8),
          Text(
            'Unknown status: $status',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Please contact support or refresh the page',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== BUILD STEP INDICATOR ====================
  Widget _buildStepIndicator(String step, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD HEADER ====================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.restaurant, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Pick up order from',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            widget.controller.messName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== BUILD INFO CARD ====================
  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // ==================== BUILD INFO ROW ====================
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ACTION METHODS ====================

  Future<void> _markReachedPickup(BuildContext context) async {
    try {
      final success = await widget.controller.markReachedPickup();

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('✅ Reached pickup location!'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Trigger animation for next slider
        _animationController.reset();
        _animationController.forward();

        setState(() {});
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to update status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markPickedUp(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Pickup'),
        content: const Text('Have you collected the order from the mess?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Yes, Picked Up'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await widget.controller.markPickedUp();

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('✅ Order picked up! Now deliver to customer'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Trigger animation for next slider
        _animationController.reset();
        _animationController.forward();

        setState(() {});
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to mark as picked up'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markDelivered(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: const Text('Have you delivered the order to the customer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Yes, Delivered'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await widget.controller.markDelivered();

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.celebration, color: Colors.white),
                SizedBox(width: 12),
                Text('🎉 Order delivered successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        setState(() {});

        // Navigate back after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.pop(context);
          }
        });
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to mark as delivered'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _callMess(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMaps(double? lat, double? lng) async {
    if (lat == null || lng == null) return;

    final Uri googleMapsUri = Uri.parse('google.navigation:q=$lat,$lng');
    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri);
      return;
    }

    final Uri webUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri);
    }
  }
}