// lib/screens/delivery/delivery_confirmation_screen.dart
import 'package:flutter/material.dart';
import '../../../models/delivery_model.dart';

class DeliveryConfirmationScreen extends StatelessWidget {
  final DeliveryModel order;

  const DeliveryConfirmationScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final delivered = order.status.toLowerCase() == 'delivered';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            delivered ? Icons.celebration : Icons.delivery_dining,
            size: 72,
            color: delivered ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            delivered ? 'Order Delivered' : 'On the way',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            delivered
                ? 'You have successfully delivered the order to the customer.'
                : 'Deliver the order to the customer and complete with OTP.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(order.customerName ?? ''),
            subtitle: Text(order.deliveryAddress ?? ''),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.currency_rupee),
            title: Text('${order.amount}'),
            subtitle: const Text('Total earnings (including delivery fee)'),
          ),
          const Spacer(),
          if (delivered)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // back to home
                },
                child: const Text('Back to Home'),
              ),
            ),
        ],
      ),
    );
  }
}
