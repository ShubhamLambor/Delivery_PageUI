import 'package:deliveryui/screens/delivery/widgets/delivery_confirmation_screen.dart';
import 'package:deliveryui/screens/delivery/widgets/navigation_screen.dart';
import 'package:deliveryui/screens/delivery/widgets/order_status_stepper.dart';
import 'package:deliveryui/screens/delivery/widgets/pickup_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'order_tracking_controller.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  final String deliveryPartnerId;

  const OrderTrackingScreen({
    Key? key,
    required this.orderId,
    required this.deliveryPartnerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrderTrackingController(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
      )..loadOrderDetails(orderId),
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
      case 'accepted':
      case 'confirmed':
      case 'waiting_for_order':
      case 'waiting_for_pickup':
      case 'ready':
      case 'ready_for_pickup':
      case 'at_pickup_location':
      case 'atpickuplocation':
      case 'reached_pickup':        // ✅ ADDED
      case 'reachedpickup':          // ✅ ADDED
      case '':                       // ✅ Handle empty status
        return PickupScreen(controller: controller);

      case 'picked_up':
      case 'pickedup':
      case 'out_for_delivery':
      case 'outfordelivery':
      case 'in_transit':
      case 'intransit':
        return NavigationScreen(controller: controller);

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
                'Unknown status: "$status"',  // ✅ Show exact status
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        );
    }
  }
}
