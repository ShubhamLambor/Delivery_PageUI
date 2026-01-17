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
      )..loadOrderDetails(orderId),  // ✅ Call loadOrderDetails here
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
    switch (controller.orderStatus.toLowerCase()) {
      case 'accepted':
      case 'confirmed':  // ✅ ADDED: Handle confirmed status
      case 'waiting_for_order':  // ✅ ADDED
      case 'waiting_for_pickup':  // ✅ ADDED
      case 'ready':
      case 'ready_for_pickup':
      case 'at_pickup_location':
        return PickupScreen(controller: controller);

      case 'picked_up':
      case 'out_for_delivery':
      case 'in_transit':
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
                'Unknown status: ${controller.orderStatus}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        );
    }
  }
}
