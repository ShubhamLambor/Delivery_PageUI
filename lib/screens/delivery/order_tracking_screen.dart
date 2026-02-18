import 'dart:async';
import 'package:deliveryui/screens/delivery/widgets/delivery_confirmation_screen.dart';
import 'package:deliveryui/screens/delivery/widgets/navigation_screen.dart';
import 'package:deliveryui/screens/delivery/widgets/order_status_stepper.dart';
import 'package:deliveryui/screens/delivery/widgets/pickup_screen.dart';
import 'package:deliveryui/screens/delivery/widgets/waiting_for_order_screen.dart';
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

  /// ✅ Auto-refresh order details every 5 seconds
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final controller =
      Provider.of<OrderTrackingController>(context, listen: false);

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

          final status = controller.orderStatus.toLowerCase().trim();
          final isDelivered = status == 'delivered';

          return WillPopScope(
            onWillPop: () async {
              if (!isDelivered) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Complete this delivery before leaving the screen.',
                    ),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
                return false; // 🔒 block back until delivered
              }
              return true; // ✅ allow back after delivered
            },
            child: Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    OrderStatusStepper(
                      currentStatus: controller.orderStatus,
                    ),
                    Expanded(
                      child: _buildContentForStatus(controller),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentForStatus(OrderTrackingController controller) {
    final status = controller.orderStatus.toLowerCase().trim();

    // 🔍 CRITICAL DEBUG LINE - SEE WHAT STATUS IS ACTUALLY RETURNED
    debugPrint('🔍🔍🔍 ROUTING SCREEN FOR STATUS: "$status" 🔍🔍🔍');

    // ✅ STEP 1: After accept - Show PickupScreen with "Reached Pickup" slider
    if (status == 'accepted' ||
        status == 'confirmed' ||
        status == 'assigned' ||
        status == '') {
      debugPrint('✅ Showing PickupScreen with "Reached Pickup" slider');
      return PickupScreen(controller: controller);
    }

    // ✅ STEP 2: After reaching mess OR order ready - Show PickupScreen with "Mark Picked Up" slider
    if (status == 'at_pickup_location' ||
        status == 'atpickuplocation' ||
        status == 'reached_pickup' ||
        status == 'reachedpickup' ||
        status == 'ready' ||
        status == 'ready_for_pickup' ||
        status == 'waiting_for_order' ||
        status == 'waiting_for_pickup') {
      debugPrint('✅ Showing PickupScreen with "Mark Picked Up" slider');
      return PickupScreen(controller: controller);
    }

    // ✅ STEP 3: When picked up - Show NavigationScreen
    if (status == 'picked_up' ||
        status == 'pickedup' ||
        status == 'out_for_delivery' ||
        status == 'outfordelivery' ||
        status == 'in_transit' ||
        status == 'intransit') {
      debugPrint('✅ Showing NavigationScreen');
      return NavigationScreen(controller: controller);
    }

    // ✅ STEP 4: Delivered
    if (status == 'delivered') {
      debugPrint('✅ Showing DeliveryConfirmationScreen');
      return DeliveryConfirmationScreen(controller: controller);
    }

    // ✅ DEFAULT: Unknown status - Show WaitingForOrderScreen
    debugPrint(
        '⚠️ Unknown status "$status" detected - showing WaitingForOrderScreen');
    return WaitingForOrderScreen(controller: controller);
  }
}
