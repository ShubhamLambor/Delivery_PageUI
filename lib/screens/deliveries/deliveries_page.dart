// lib/screens/deliveries/deliveries_page.dart
import 'package:deliveryui/screens/deliveries/widgets/delivery_filter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'deliveries_controller.dart';
import 'widgets/delivery_tile.dart'; // adjust import to your path

class DeliveriesPage extends StatelessWidget {
  const DeliveriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DeliveriesController>();
    final deliveries = controller.filteredDeliveries;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Deliveries',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.black),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Tabs
            Row(
              children: [
                _chip(context, 'All'),
                const SizedBox(width: 5),
                _chip(context, 'Pending'),
                const SizedBox(width: 5),
                _chip(context, 'Completed'),
                const SizedBox(width: 5),
                _chip(context, 'Cancelled'),
              ],
            ),
            const SizedBox(height: 16),

            // Summary card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryItem(
                    Icons.assignment,
                    '${controller.totalCount}',
                    'Total Assigned',
                  ),
                  _summaryItem(
                    Icons.check_circle,
                    '${controller.completedCount}',
                    'Delivered',
                  ),
                  _summaryItem(
                    Icons.cancel,
                    '${controller.cancelledCount}',
                    'Cancelled',
                  ),
                  _summaryItem(
                    Icons.access_time,
                    '${controller.pendingCount}',
                    'Pending',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filter'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.sort),
                    label: const Text('Sort by Time'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // List
            Expanded(
              child: ListView.builder(
                itemCount: deliveries.length,
                itemBuilder: (context, index) {
                  final d = deliveries[index];
                  return DeliveryTile(
                    delivery: d,
                    onTap: () {
                      // Example dynamic actions
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => _DeliveryActionsSheet(deliveryId: d.id),
                      );
                    },
                  );
                },
              ),
            ),

            // Help section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Need Help? Stay on time to earn incentives!',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Support'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label) {
    final controller = context.watch<DeliveriesController>();
    final bool selected = controller.filter == label;

    return GestureDetector(
      onTap: () => controller.changeFilter(label),
      child: Container(
        padding:
        const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.green : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _DeliveryActionsSheet extends StatelessWidget {
  final String deliveryId;

  const _DeliveryActionsSheet({super.key, required this.deliveryId});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DeliveriesController>();

    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Mark as Completed'),
            onTap: () {
              controller.markCompleted(deliveryId);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.red),
            title: const Text('Mark as Cancelled'),
            onTap: () {
              controller.markCancelled(deliveryId);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
