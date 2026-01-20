// lib/screens/home/home_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Controllers & Services
import '../delivery/order_tracking_screen.dart';
import 'home_controller.dart';
import '../auth/auth_controller.dart';
import '../deliveries/deliveries_controller.dart';
import '../map/osm_navigation_screen.dart';
import '../chatbot/chatbot_page.dart';
import '../../services/delivery_service.dart';

// Models
import '../../models/delivery_model.dart';

// Widgets
import 'widgets/current_delivery_card.dart';
import 'widgets/new_order_card.dart';
import 'widgets/upcoming_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ Check mounted before everything
      if (!mounted) return;

      requestLocationPermission();

      // Get partner ID from AuthController
      final auth = context.read<AuthController>();
      final partnerId = auth.getCurrentUserId();

      if (partnerId == null || partnerId.isEmpty) {
        debugPrint('❌ Cannot initialize: User ID is null/invalid');
        return;
      }

      // Initialize HomeController with partner ID
      final home = context.read<HomeController>();
      home.initialize(partnerId).then((_) {
        debugPrint('✅ HomeController initialized');
        // ✅ FIXED: Check if widget is still mounted before starting polling
        if (mounted) {
          startPolling();
        }
      }).catchError((error) {
        debugPrint('❌ HomeController initialization failed: $error');
      });
    });
  }

  /// ✅ FIXED: Start polling with proper mounted checks
  void startPolling() {
    // ✅ Check if widget is mounted first
    if (!mounted) {
      debugPrint('⚠️ Cannot start polling: Widget is unmounted');
      return;
    }

    final auth = context.read<AuthController>();
    final uid = auth.getCurrentUserId();

    if (uid == null || uid.isEmpty) {
      debugPrint('❌ Cannot start polling: User ID is null/invalid');
      return;
    }

    debugPrint('📡 Starting order polling for partner: $uid...');

    pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      // ✅ Check mounted before each iteration
      if (!mounted) {
        timer.cancel();
        debugPrint('⚠️ Stopping polling: Widget unmounted');
        return;
      }

      final home = context.read<HomeController>();
      if (!home.isOnline) return; // skip when offline

      try {
        final result = await DeliveryService.checkPendingAssignments(uid);
        final assignment = result['assignment'];

        if (result['success'] == true &&
            result['has_pending'] == true &&
            assignment != null &&
            assignment is Map) {
          debugPrint('🆕 NEW ORDER DETECTED!');
          debugPrint('   Order ID: ${assignment['order_id']}');
          debugPrint('   Mess: ${assignment['mess_name']}');
          debugPrint('   Amount: ${assignment['total_amount']}');
          debugPrint('   Address: ${assignment['delivery_address']}');

          // Stop polling while dialog is open
          timer.cancel();

          // ✅ FIX: Cast Map to Map<String, dynamic>
          if (mounted) {
            showNewOrderDialog(Map<String, dynamic>.from(assignment));
          }
        }
      } catch (e) {
        debugPrint('❌ Polling error: $e');
      }
    });
  }

  /// Stop polling timer
  void stopPolling() {
    if (pollingTimer != null) {
      pollingTimer!.cancel();
      pollingTimer = null;
      debugPrint('🛑 Stopped order polling');
    }
  }

  /// ✅ NEW: Pull-to-refresh functionality
  Future _handleRefresh() async {
    if (!mounted) return;
    debugPrint('🔄 Manual refresh triggered...');

    final home = context.read<HomeController>();
    final deliveries = context.read<DeliveriesController>();

    try {
      // Refresh all data in parallel
      await Future.wait([
        home.refresh(),
        deliveries.fetchDeliveries(),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Data refreshed successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      debugPrint('✅ Manual refresh completed');
    } catch (e) {
      debugPrint('❌ Error during manual refresh: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Failed to refresh data'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }


  /// Show new order dialog with Accept/Reject options
  void showNewOrderDialog(Map<String, dynamic> assignment) {
    if (!mounted) return;

    final auth = context.read<AuthController>();
    final uid = auth.getCurrentUserId() ?? '';

    debugPrint('📢 SHOWING DIALOG NOW...');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_active, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'NEW ORDER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Order Details
            _buildDetailRow(
              Icons.shopping_bag,
              'Order ID',
              assignment['order_id']?.toString() ?? 'N/A',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.store,
              'Mess',
              assignment['mess_name']?.toString() ?? 'N/A',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.location_on,
              'Delivery Address',
              assignment['delivery_address']?.toString() ??
                  'Address will be provided',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.currency_rupee,
              'Amount',
              assignment['total_amount']?.toString() ?? '0',
            ),
            const SizedBox(height: 24),
            // Action Buttons
            Row(
              children: [
                // Reject Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _handleRejectFromDialog(
                        assignment['order_id']?.toString() ?? '',
                        uid,
                      );
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Accept Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _handleAcceptFromDialog(
                        assignment['order_id']?.toString() ?? '',
                        uid,
                      );
                    },
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('Accept Order'),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build detail row widget
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
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

  /// Handle accept from dialog
  Future<void> _handleAcceptFromDialog(String orderId, String partnerId) async {
    debugPrint('✅ Accepting order from dialog: $orderId');
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Accepting order...'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }

      final result = await DeliveryService.acceptOrder(
        orderId: orderId,
        deliveryPartnerId: partnerId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Order accepted successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          debugPrint('✅ Refreshing deliveries after accept...');

          // Refresh deliveries
          try {
            final deliveriesController = context.read<DeliveriesController>();
            await deliveriesController.fetchDeliveries();
            debugPrint('✅ DeliveriesController refreshed');
          } catch (e) {
            debugPrint('⚠️ DeliveriesController not found: $e');
          }

          final homeController = context.read<HomeController>();
          await homeController.fetchDeliveries();
          debugPrint('✅ HomeController refreshed');

          if (mounted) {
            setState(() {});
          }

          // Navigate to OrderTrackingScreen
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderTrackingScreen(
                  orderId: orderId,
                  deliveryPartnerId: partnerId,
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(result['message'] ?? 'Failed to accept order'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error accepting order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Error accepting order'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        startPolling();
      }
    }
  }

  /// Handle reject from dialog
  Future<void> _handleRejectFromDialog(String orderId, String partnerId) async {
    debugPrint('❌ Rejecting order from dialog: $orderId');
    try {
      final result = await DeliveryService.rejectOrder(
        orderId: orderId,
        deliveryPartnerId: partnerId,
        reason: 'User declined',
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
              Text(result['message'] ?? 'Order rejected and reassigned'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to reject order'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error rejecting order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error rejecting order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        startPolling();
      }
    }
  }

  /// Handle Mark as Picked Up
  void _handleMarkPickedUp(BuildContext context, String orderId) async {
    final auth = context.read<AuthController>();
    final partnerId = auth.getCurrentUserId() ?? '';

    debugPrint('📦 Marking order as picked up: $orderId');

    try {
      final result = await DeliveryService.markPickedUp(
        orderId: orderId,
        deliveryPartnerId: partnerId,
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order marked as picked up!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );

          final deliveriesController = context.read<DeliveriesController>();
          await deliveriesController.fetchDeliveries();

          final homeController = context.read<HomeController>();
          await homeController.fetchDeliveries();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
              Text(result['message'] ?? 'Failed to mark as picked up'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error marking as picked up: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error marking as picked up'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle Mark as In Transit
  void _handleMarkInTransit(BuildContext context, String orderId) async {
    final auth = context.read<AuthController>();
    final partnerId = auth.getCurrentUserId() ?? '';

    debugPrint('🚚 Marking order as in transit: $orderId');

    try {
      final result = await DeliveryService.markInTransit(
        orderId: orderId,
        deliveryPartnerId: partnerId,
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order marked as in transit!'),
              backgroundColor: Colors.purple,
              duration: Duration(seconds: 2),
            ),
          );

          final deliveriesController = context.read<DeliveriesController>();
          await deliveriesController.fetchDeliveries();

          final homeController = context.read<HomeController>();
          await homeController.fetchDeliveries();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
              Text(result['message'] ?? 'Failed to mark as in transit'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error marking as in transit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error marking as in transit'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle Mark as Delivered
  void _handleMarkDelivered(BuildContext context, String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Confirm Delivery'),
          ],
        ),
        content: const Text(
          'Have you delivered this order to the customer?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Confirm Delivery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final auth = context.read<AuthController>();
      final partnerId = auth.getCurrentUserId() ?? '';

      debugPrint('✅ Marking order as delivered: $orderId');

      try {
        final result = await DeliveryService.markDelivered(
          orderId: orderId,
          deliveryPartnerId: partnerId,
          notes: 'Delivered successfully',
        );

        if (mounted) {
          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Order delivered successfully!'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );

            final deliveriesController = context.read<DeliveriesController>();
            await deliveriesController.fetchDeliveries();

            final homeController = context.read<HomeController>();
            await homeController.fetchDeliveries();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                Text(result['message'] ?? 'Failed to mark as delivered'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Error marking as delivered: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error marking as delivered'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Location Permission
  Future<void> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _showLocationServiceDialog();
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          _showPermissionDeniedDialog();
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showPermissionPermanentlyDeniedDialog();
      }
      return;
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('App needs location access.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              requestLocationPermission();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Denied'),
        content: const Text('Enable location in settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Geolocator.openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  /// Navigate to Mess
  Future<void> _navigateToMess() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OSMNavigationScreen(
          destinationLat: 19.0760,
          destinationLng: 72.8777,
          destinationName: 'Shree Kitchen',
        ),
      ),
    );
  }

  /// ✅ FIXED: Handle Accept Order (from NewOrderCard)
  void handleAcceptOrder(BuildContext context, String orderId) async {
    final deliveriesController = context.read<DeliveriesController>();
    try {
      final success = await deliveriesController.acceptOrder(orderId);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order accepted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((deliveriesController.errorMessage?.isNotEmpty ?? false)
                ? deliveriesController.errorMessage!
                : 'Failed to accept order'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// ✅ FIXED: Handle Reject Order (from NewOrderCard)
  void handleRejectOrder(BuildContext context, String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order?'),
        content: const Text('Are you sure you want to reject this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final deliveriesController = context.read<DeliveriesController>();
      try {
        final success = await deliveriesController.rejectOrder(orderId,
            reason: 'User declined');
        if (mounted && success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order rejected'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text((deliveriesController.errorMessage?.isNotEmpty ?? false)
                  ? deliveriesController.errorMessage!
                  : 'Failed to reject order'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final auth = context.watch<AuthController>();
    final deliveriesController = context.watch<DeliveriesController>();

    // Fallback to DeliveriesController counts if Home stats are zero
    final completed = home.completedCount == 0
        ? deliveriesController.completedCount
        : home.completedCount;

    final pending = home.pendingCount == 0
        ? deliveriesController.pendingCount
        : home.pendingCount;

    final cancelled = home.cancelledCount == 0
        ? deliveriesController.cancelledCount
        : home.cancelledCount;

    final DeliveryModel? current = home.currentDelivery;
    final List<DeliveryModel> upcoming = home.upcomingDeliveries;
    final List<DeliveryModel> newOrders = deliveriesController.newOrders;

    final bool isOnline = home.isOnline;
    final String userName = auth.user?.name ?? 'Delivery Partner';
    final now = DateTime.now();
    final dateStr = DateFormat('EEE, d MMM').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.green,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ===== HEADER SECTION =====
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                height: 240,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOnline
                        ? [const Color(0xFF2E7D32), const Color(0xFF4CAF50)]
                        : [const Color(0xFFC62828), const Color(0xFFEF5350)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // User Name & Date
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $userName',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action Icons
                        Row(
                          children: [
                            // ❌ REMOVED: Refresh Button
                            // Chat Button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.support_agent,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ChatbotPage(),
                                    ),
                                  );
                                },
                                tooltip: 'Support Assistant',
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Profile Icon
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.person,
                                  color: isOnline ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Swipe Toggle Button
                    _SwipeToggleButton(
                      isOnline: isOnline,
                      onToggle: home.isLoading ? null : home.toggleOnline,
                    ),
                  ],
                ),
              ),


              // ===== STATS GRID =====
              // STATS GRID
              Transform.translate(
                offset: const Offset(0, -60),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatCard(
                        'Today\'s Earnings',
                        home.todayEarnings.toString(),
                        Icons.currency_rupee,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Completed',
                        completed.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Pending',
                        pending.toString(),
                        Icons.access_time,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Cancelled',
                        cancelled.toString(),
                        Icons.cancel,
                        Colors.red,
                      ),
                    ],
                  ),
                ),
              ),


              // ===== MAIN CONTENT =====
              Transform.translate(
                offset: const Offset(0, -80),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // NEW ORDERS
                      if (newOrders.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'New Orders',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${newOrders.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...newOrders.map((order) {
                          return NewOrderCard(
                            order: order,
                            onAccept: () => handleAcceptOrder(context, order.id),
                            onReject: () => handleRejectOrder(context, order.id),
                          );
                        }).toList(),
                        const SizedBox(height: 24),
                      ],

                      // ACTIVE DELIVERY
                      const Text(
                        'Active Delivery',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (current != null)
                        CurrentDeliveryCard(
                          key: ValueKey('active_${current.id}'),
                          delivery: current,
                          onCall: () {
                            debugPrint(
                                '📞 Calling customer: ${current.customerName}');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Call functionality coming soon!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          onPickedUp: () =>
                              _handleMarkPickedUp(context, current.id),
                          onInTransit: () =>
                              _handleMarkInTransit(context, current.id),
                          onDelivered: () =>
                              _handleMarkDelivered(context, current.id),
                        )
                      else
                        _buildEmptyActiveDelivery(isOnline),
                      const SizedBox(height: 24),

                      // NEXT PICKUP
                      const Text(
                        'Next Pickup',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPickupCard(),
                      const SizedBox(height: 24),

                      // UPCOMING ORDERS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Upcoming Orders',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${upcoming.length}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (upcoming.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'No upcoming orders',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: upcoming
                              .map((d) => UpcomingTile(delivery: d))
                              .toList(),
                        ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== UI HELPER WIDGETS =====
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
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
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.store,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shree Kitchen',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Pickup Point',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '25 Tiffins',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '10:15 - 10:45 AM',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToMess,
              icon: const Icon(Icons.navigation, size: 18),
              label: const Text('Navigate to Mess'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActiveDelivery(bool isOnline) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline ? Colors.green.shade100 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isOnline
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOnline ? Icons.search : Icons.power_settings_new,
              size: 40,
              color: isOnline ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isOnline
                ? 'Searching for orders...'
                : 'Go online to receive orders',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isOnline
                ? 'New delivery requests will appear here'
                : 'Toggle online above to start accepting deliveries',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (isOnline) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLoadingDot(0),
                const SizedBox(width: 8),
                _buildLoadingDot(200),
                const SizedBox(width: 8),
                _buildLoadingDot(400),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingDot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Opacity(
          opacity: ((value * 2) % 2) > 1 ? 2 - (value * 2) % 2 : (value * 2) % 2,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }
}

// ===== SWIPE TOGGLE BUTTON =====
class _SwipeToggleButton extends StatefulWidget {
  final bool isOnline;
  final VoidCallback? onToggle;

  const _SwipeToggleButton({
    required this.isOnline,
    required this.onToggle,
  });

  @override
  State<_SwipeToggleButton> createState() => _SwipeToggleButtonState();
}

class _SwipeToggleButtonState extends State<_SwipeToggleButton> {
  double dragPosition = 0.0;
  bool isDragging = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width - 40;
    const height = 54.0;
    final thumbWidth = screenWidth / 2;
    final maxDrag = screenWidth - thumbWidth;
    final targetPosition = widget.isOnline ? maxDrag : 0.0;
    final currentPosition = isDragging ? dragPosition : targetPosition;
    final dragPercentage = (currentPosition / maxDrag).clamp(0.0, 1.0);
    final backgroundColor = Color.lerp(
      Colors.red.shade400,
      Colors.green.shade600,
      dragPercentage,
    )!;
    final canToggle = widget.onToggle != null;

    return Opacity(
      opacity: canToggle ? 1.0 : 0.6,
      child: Container(
        height: height,
        width: screenWidth,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: !widget.isOnline && !isDragging ? 1.0 : 0.5,
                      duration: const Duration(milliseconds: 200),
                      child: const Text(
                        'Offline',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: widget.isOnline && !isDragging ? 1.0 : 0.5,
                      duration: const Duration(milliseconds: 200),
                      child: const Text(
                        'Online',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AnimatedPositioned(
              duration: isDragging
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              left: currentPosition,
              top: 2,
              bottom: 2,
              child: GestureDetector(
                onHorizontalDragStart: canToggle
                    ? (_) => setState(() {
                  isDragging = true;
                  dragPosition = targetPosition;
                })
                    : null,
                onHorizontalDragUpdate: canToggle
                    ? (d) => setState(() {
                  dragPosition =
                      (dragPosition + d.delta.dx).clamp(0.0, maxDrag);
                })
                    : null,
                onHorizontalDragEnd: canToggle
                    ? (_) => setState(() {
                  isDragging = false;
                  if (dragPosition > maxDrag / 2 && !widget.isOnline) {
                    widget.onToggle?.call();
                  } else if (dragPosition < maxDrag / 2 &&
                      widget.isOnline) {
                    widget.onToggle?.call();
                  } else {
                    dragPosition = widget.isOnline ? maxDrag : 0.0;
                  }
                })
                    : null,
                onTap: canToggle
                    ? () {
                  if (!isDragging) {
                    widget.onToggle?.call();
                  }
                }
                    : null,
                child: Container(
                  width: thumbWidth - 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isOnline
                            ? Icons.verified_user
                            : Icons.power_settings_new,
                        color: backgroundColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: backgroundColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
