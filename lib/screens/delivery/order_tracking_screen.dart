// lib/screens/delivery/order_tracking_screen.dart
import 'package:deliveryui/screens/delivery/widgets/delivery_confirmation_screen.dart';
import 'package:deliveryui/screens/delivery/widgets/order_status_stepper.dart';
import 'package:deliveryui/screens/delivery/widgets/pickup_screen.dart';
import 'package:deliveryui/screens/delivery/widgets/waiting_for_order_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'order_tracking_controller.dart';
import '../map/osm_navigation_screen.dart';
import '../../models/delivery_model.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  final String deliveryPartnerId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    required this.deliveryPartnerId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OrderTrackingController>(
      create: (_) => OrderTrackingController(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
      )..loadOrderDetails(),
      child: const _OrderTrackingView(),
    );
  }
}

class _OrderTrackingView extends StatelessWidget {
  const _OrderTrackingView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrderTrackingController>();

    final order = controller.order;
    final isLoading = controller.isLoading && order == null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order ${controller.orderId}'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : order == null
          ? Center(
        child: Text(controller.errorMessage ?? 'Order not found'),
      )
          : Column(
        children: [
          OrderStatusStepper(
            status: controller.status,
            assignmentStatus: controller.assignmentStatus,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildStageScreen(context, controller, order),
          ),
        ],
      ),
    );
  }

  Widget _buildStageScreen(
      BuildContext context,
      OrderTrackingController c,
      DeliveryModel order,
      ) {
    // Final stage
    if (c.isDelivered) {
      return DeliveryConfirmationScreen(order: order);
    }

    // Picked up / out_for_delivery stage
    if (c.isPickedUp) {
      return DeliveryConfirmationScreen(order: order);
    }

    // At pickup: assignment_status == 'at_pickup'
    if (c.isAtPickup) {
      return PickupScreen(
        order: order,
        isUpdating: c.isUpdating,
        // at_pickup already set in DB -> don't call reached_pickup again
        onReachedPickup: () async {},
        onPickedUp: () async {
          await c.markPickedUp(); // picked_up
        },
        onNavigateToMess: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OSMNavigationScreen(
                destinationLat: order.pickupLatitude!,
                destinationLng: order.pickupLongitude!,
                destinationName: order.messName ?? 'Pickup',
              ),
            ),
          );
        },
      );
    }

    // Default: confirmed + accepted/assigned, not yet at pickup
    return WaitingForOrderScreen(
      order: order,
      isUpdating: c.isUpdating,
      onNavigateToMess: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OSMNavigationScreen(
              destinationLat: order.pickupLatitude!,
              destinationLng: order.pickupLongitude!,
              destinationName: order.messName ?? 'Pickup',
            ),
          ),
        );
      },
      onReachedPickup: () async {
        // First and only place that calls reached_pickup
        if (!c.isAtWaiting) return;
        await c.markReachedPickup();
      },
    );
  }
}
