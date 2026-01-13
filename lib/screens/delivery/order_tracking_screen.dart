import 'package:deliveryui/screens/delivery/widgets/delivery_confirmation_screen.dart';
import 'package:deliveryui/screens/delivery/widgets/navigation_screen.dart';
import 'package:deliveryui/screens/delivery/widgets/order_status_stepper.dart';
import 'package:deliveryui/screens/delivery/widgets/pickup_screen.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderTrackingController>().loadOrderDetails(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OrderTrackingController(
        orderId: widget.orderId,
        deliveryPartnerId: widget.deliveryPartnerId,
      ),
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
    switch (controller.orderStatus) {
      case 'accepted':
      case 'out_for_delivery':
        return PickupScreen(controller: controller);

      case 'picked_up':
        return NavigationScreen(controller: controller);

      case 'delivered':
        return DeliveryConfirmationScreen(controller: controller);

      default:
        return const Center(child: Text('Unknown status'));
    }
  }
}
