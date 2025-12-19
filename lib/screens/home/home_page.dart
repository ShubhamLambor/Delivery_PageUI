import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_controller.dart';
import '../../screens/home/widgets/current_delivery_card.dart';
import '../../screens/home/widgets/stats_card.dart';
import '../../models/delivery_model.dart';
import 'widgets/upcoming_tile.dart';
import '../auth/auth_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final auth = context.watch<AuthController>(); // Firebase user

    final DeliveryModel? current = home.currentDelivery;
    final List<DeliveryModel> upcoming = home.upcomingDeliveries;

    final total = home.totalCount;
    final completed = home.completedCount;
    final pending = home.pendingCount;
    final cancelled = home.cancelledCount;
    final isOnline = home.isOnline;

    final userName = auth.user?.name ?? 'Delivery Partner';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Delivery Boy',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications, color: Colors.black),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Share'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.lightBlueAccent,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Today',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: home.toggleOnline,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: (isOnline ? Colors.green : Colors.red)
                                .withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isOnline ? Icons.flash_on : Icons.flash_off,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              isOnline
                                  ? Icons.check_circle
                                  : Icons.pause_circle_filled,
                              key: ValueKey(isOnline),
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.8,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatsCard(
                  title: 'Total Deliveries Today',
                  value: '$total',
                  icon: Icons.local_shipping,
                  color: Colors.blue,
                ),
                StatsCard(
                  title: 'Completed',
                  value: '$completed',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                StatsCard(
                  title: 'Pending',
                  value: '$pending',
                  icon: Icons.access_time,
                  color: Colors.orange,
                ),
                const StatsCard(
                  title: 'Today\'s Earnings',
                  value: '₹320',
                  icon: Icons.currency_rupee,
                  color: Colors.purple,
                ),
                StatsCard(
                  title: 'Order Completed',
                  value: '$completed',
                  icon: Icons.done_all,
                  color: Colors.teal,
                ),
                StatsCard(
                  title: 'Order Cancelled',
                  value: '$cancelled',
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Current Delivery
            if (current != null) ...[
              CurrentDeliveryCard(delivery: current),
              const SizedBox(height: 16),
            ],

            // Pickup Section
            _buildPickupSection(),

            const SizedBox(height: 16),

            // Upcoming Deliveries Section
            _buildUpcomingSection(upcoming),
          ],
        ),
      ),
    );
  }

  // ---- PICKUP SECTION ----
  Widget _buildPickupSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 30),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.store, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Pickup Point',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Shree Kitchen',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '25 Tiffins Ready',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: const [
                Icon(Icons.access_time, color: Colors.orange, size: 14),
                SizedBox(width: 6),
                Text(
                  'Pickup: 10:15 - 10:45 AM',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.navigation),
            label: const Text('Navigate to Mess'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }

  // ---- UPCOMING SECTION ----
  Widget _buildUpcomingSection(List<DeliveryModel> upcoming) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 30),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Deliveries',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${upcoming.length} pending',
                  style: const TextStyle(
                      color: Colors.orange, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children:
            upcoming.map((d) => UpcomingTile(delivery: d)).toList(),
          ),
        ],
      ),
    );
  }
}
