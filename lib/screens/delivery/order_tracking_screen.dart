import 'dart:async';
import 'package:deliveryui/screens/delivery/widgets/delivery_confirmation_screen.dart';
import 'package:deliveryui/screens/delivery/widgets/navigation_screen.dart';
import 'package:deliveryui/screens/delivery/widgets/order_status_stepper.dart';
import 'package:deliveryui/screens/delivery/widgets/pickup_screen.dart';
import 'package:deliveryui/screens/delivery/widgets/waiting_for_order_screen.dart'; // ✅ ADD THIS
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'order_tracking_controller.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final String deliveryPartnerId;

  const OrderTrackingScreen({
    Key? key,
    required this.orderId,
    required this.deliveryPartnerId,
  }) : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// ✅ Auto-refresh order details every 10 seconds
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      final controller = context.read<OrderTrackingController>();

      // ✅ Only refresh if order is not delivered
      if (controller.orderStatus.toLowerCase() != 'delivered') {
        debugPrint('🔄 Auto-refreshing order details...');
        controller.loadOrderDetails(widget.orderId);
      } else {
        timer.cancel();
        debugPrint('✅ Order delivered. Stopped auto-refresh.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrderTrackingController(
        orderId: widget.orderId,
        deliveryPartnerId: widget.deliveryPartnerId,
      )..loadOrderDetails(widget.orderId),
      child: Consumer<OrderTrackingController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  // Status Stepper Header
                  OrderStatusStepper(
                    currentStatus: controller.orderStatus,
                  ),
                  // Main Content based on status
                  Expanded(
                    child: _buildContentForStatus(controller),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentForStatus(OrderTrackingController controller) {
    final status = controller.orderStatus.toLowerCase().trim();

    switch (status) {
    // ✅ STEP 1: Show "Waiting" screen when order is accepted/confirmed
      case 'accepted':
      case 'confirmed':
      case 'waiting_for_order':
      case 'waiting_for_pickup':
      case '':  // Empty status
        return WaitingForOrderScreen(controller: controller);

    // ✅ STEP 2: Show "Pickup" screen when order is ready
      case 'ready':
      case 'ready_for_pickup':
      case 'at_pickup_location':
      case 'atpickuplocation':
      case 'reached_pickup':
      case 'reachedpickup':
        return PickupScreen(controller: controller);

    // ✅ STEP 3: Show "Navigation" screen when picked up
      case 'picked_up':
      case 'pickedup':
      case 'out_for_delivery':
      case 'outfordelivery':
      case 'in_transit':
      case 'intransit':
        return NavigationScreen(controller: controller);

    // ✅ STEP 4: Show "Confirmation" screen when delivered
      case 'delivered':
        return DeliveryConfirmationScreen(controller: controller);

      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Unknown status: "$status"',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => controller.loadOrderDetails(widget.orderId),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        );
    }
  }
}
