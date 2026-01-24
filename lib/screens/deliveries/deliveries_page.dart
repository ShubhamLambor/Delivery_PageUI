// lib/screens/deliveries/deliveries_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'deliveries_controller.dart';
import '../../models/delivery_model.dart';

class DeliveriesPage extends StatefulWidget {
  const DeliveriesPage({super.key});

  @override
  State<DeliveriesPage> createState() => _DeliveriesPageState();
}

class _DeliveriesPageState extends State<DeliveriesPage> {
  bool isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllDeliveries();
    });
  }

  Future<void> _loadAllDeliveries() async {
    final controller = context.read<DeliveriesController>();
    setState(() => isLoadingHistory = true);

    try {
      await controller.fetchDeliveries();
    } finally {
      if (mounted) {
        setState(() => isLoadingHistory = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadAllDeliveries();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DeliveriesController>();
    final deliveries = controller.filteredDeliveries;

    // Calculate summary stats based on filtered deliveries
    final totalEarnings = deliveries
        .where((d) => d.status.toLowerCase() == 'delivered')
        .fold(0.0, (sum, d) {
      final amount = double.tryParse(d.amount ?? '0') ?? 0.0;
      return sum + amount;
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          slivers: [
            // 1. Header with Stats
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
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
                        const Text(
                          'Deliveries',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // ✅ Show loading indicator when fetching history
                        if (isLoadingHistory)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        else
                          IconButton(
                            onPressed: _handleRefresh,
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            tooltip: 'Refresh',
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Stats Container
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _headerStatItem(
                              context, '${controller.totalCount}', 'Total'),
                          _verticalDivider(),
                          _headerStatItem(
                              context, '${controller.completedCount}', 'Done'),
                          _verticalDivider(),
                          _headerStatItem(
                              context, '${controller.pendingCount}', 'Pending'),
                          _verticalDivider(),
                          _headerStatItem(
                              context, '${controller.cancelledCount}', 'Failed'),
                        ],
                      ),
                    ),

                    // ✅ NEW: Earnings Display
                    if (totalEarnings > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.currency_rupee, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Total Earnings: ₹${totalEarnings.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 2. Filters + Sort
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        children: [
                          _chip(context, 'All'),
                          const SizedBox(width: 8),
                          _chip(context, 'Pending'),
                          const SizedBox(width: 8),
                          _chip(context, 'Completed'),
                          const SizedBox(width: 8),
                          _chip(context, 'Cancelled'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Date and Sort Filters
                    Row(
                      children: [
                        // Filter Date button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final now = DateTime.now();
                              final controller = context.read<DeliveriesController>();

                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(now.year - 1),
                                lastDate: now,
                                initialDateRange: controller.dateRange,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Colors.green,
                                        onPrimary: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );

                              controller.setDateRange(picked);

                              // ✅ Reload with date filter
                              if (picked != null) {
                                setState(() => isLoadingHistory = true);
                                await controller.fetchOrderHistory(
                                  startDate: picked.start,
                                  endDate: picked.end,
                                );
                                if (mounted) {
                                  setState(() => isLoadingHistory = false);
                                }
                              }
                            },
                            icon: const Icon(Icons.filter_list, size: 18),
                            label: Text(
                              controller.dateRange == null
                                  ? 'Filter Date'
                                  : '${controller.dateRange!.start.day}/${controller.dateRange!.start.month}'
                                  ' - ${controller.dateRange!.end.day}/${controller.dateRange!.end.month}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        // ✅ Clear Date Filter Button
                        if (controller.dateRange != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () async {
                              final controller = context.read<DeliveriesController>();
                              controller.setDateRange(null);
                              setState(() => isLoadingHistory = true);
                              await controller.fetchDeliveries();
                              if (mounted) {
                                setState(() => isLoadingHistory = false);
                              }
                            },
                            icon: const Icon(Icons.clear, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red,
                            ),
                            tooltip: 'Clear date filter',
                          ),
                        ],

                        const SizedBox(width: 8),

                        // Sort By button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final controller = context.read<DeliveriesController>();
                              const options = ['Newest', 'Oldest', 'Amount'];

                              final selected = await showModalBottomSheet<String>(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (context) {
                                  return SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Sort by',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...options.map(
                                              (o) => ListTile(
                                            title: Text(o),
                                            trailing: controller.sortBy == o
                                                ? const Icon(
                                              Icons.check,
                                              color: Colors.green,
                                            )
                                                : null,
                                            onTap: () => Navigator.pop(context, o),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  );
                                },
                              );

                              if (selected != null) {
                                controller.setSortBy(selected);
                              }
                            },
                            icon: const Icon(Icons.sort, size: 18),
                            label: Text('Sort: ${controller.sortBy}', style: const TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ✅ Results count
                    const SizedBox(height: 12),
                    Text(
                      'Showing ${deliveries.length} ${deliveries.length == 1 ? 'delivery' : 'deliveries'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // 3. List
            if (isLoadingHistory)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Colors.green),
                ),
              )
            else if (deliveries.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inbox,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No deliveries found',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your filters',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final d = deliveries[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildDeliveryCard(context, d),
                      );
                    },
                    childCount: deliveries.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// --- Helpers ---

Widget _headerStatItem(BuildContext context, String value, String label) {
  return Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 12,
        ),
      ),
    ],
  );
}

Widget _verticalDivider() {
  return Container(
    height: 24,
    width: 1,
    color: Colors.white.withOpacity(0.2),
  );
}

Widget _chip(BuildContext context, String label) {
  final controller = context.watch<DeliveriesController>();
  final bool selected = controller.filter == label;

  return GestureDetector(
    onTap: () => controller.changeFilter(label),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
      decoration: BoxDecoration(
        color: selected ? Colors.green : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? Colors.green : Colors.grey.shade300,
        ),
        boxShadow: selected
            ? [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ]
            : [],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.grey[700],
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    ),
  );
}

Widget _buildDeliveryCard(BuildContext context, DeliveryModel delivery) {
  final statusColor = _getStatusColor(delivery.status);
  final statusIcon = _getStatusIcon(delivery.status);

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => _DeliveryActionsSheet(
              deliveryId: delivery.id,
              delivery: delivery,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          delivery.status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹${delivery.amount}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.green.shade100,
                    child: Icon(Icons.person, color: Colors.green.shade700, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          delivery.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          delivery.address,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${delivery.id.length >= 8 ? delivery.id.substring(0, 8) : delivery.id}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        delivery.time ?? 'N/A',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
    case 'delivered':
      return Colors.green;
    case 'cancelled':
    case 'rejected':
      return Colors.red;
    case 'pending':
    case 'out_for_delivery':
    case 'in_transit':
      return Colors.orange;
    default:
      return Colors.blue;
  }
}

IconData _getStatusIcon(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
    case 'delivered':
      return Icons.check_circle;
    case 'cancelled':
    case 'rejected':
      return Icons.cancel;
    default:
      return Icons.access_time;
  }
}

class _DeliveryActionsSheet extends StatelessWidget {
  final String deliveryId;
  final DeliveryModel delivery;

  const _DeliveryActionsSheet({
    required this.deliveryId,
    required this.delivery,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DeliveriesController>();
    final isCompleted = delivery.status.toLowerCase() == 'completed' ||
        delivery.status.toLowerCase() == 'delivered';
    final isCancelled = delivery.status.toLowerCase() == 'cancelled' ||
        delivery.status.toLowerCase() == 'rejected';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Order Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'Order #${deliveryId.substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    delivery.customerName,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    '₹${delivery.amount}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),

            // Actions (only show if not completed/cancelled)
            if (!isCompleted && !isCancelled) ...[
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.green),
                ),
                title: const Text('Mark as Completed'),
                onTap: () {
                  controller.markCompleted(deliveryId);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.red),
                ),
                title: const Text('Mark as Cancelled'),
                onTap: () {
                  controller.markCancelled(deliveryId);
                  Navigator.pop(context);
                },
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'This delivery is already ${delivery.status.toLowerCase()}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
