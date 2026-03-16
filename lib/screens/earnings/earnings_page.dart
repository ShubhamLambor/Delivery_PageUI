// lib/screens/earnings/earnings_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_controller.dart';
import 'earnings_controller.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  String _period = 'today'; // today | week | month | all
  bool _showStatements = false; // Toggle between recent orders and wallet statements

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchEarnings();
    });
  }

  void _fetchEarnings() {
    final auth = context.read<AuthController>();
    final partnerId = auth.getCurrentUserId() ?? '';
    if (partnerId.isNotEmpty) {
      context.read<EarningsController>().fetchEarnings(partnerId, period: _period);
    }
  }

  void _changePeriod(String period) {
    if (_period == period) return;
    setState(() => _period = period);
    _fetchEarnings();
  }

  Future<void> _onRefresh() async {
    _fetchEarnings();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _showWithdrawDialog(BuildContext context, EarningsController controller) {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Request Withdrawal', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Available: ₹${controller.availableBalance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Amount (₹)',
                  labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.green, width: 2)),
                  prefixIcon: const Icon(Icons.currency_rupee, color: Colors.black87),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount <= 0 || amount > controller.availableBalance) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount'), backgroundColor: Colors.red));
                  return;
                }
                Navigator.pop(ctx);
                final auth = context.read<AuthController>();
                final partnerId = auth.getCurrentUserId() ?? '';
                final success = await controller.requestWithdrawal(partnerId, amount);

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal requested successfully!'), backgroundColor: Colors.green));
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.error ?? 'Request failed'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EarningsController>();

    if (controller.isLoading && controller.totalEarnings == 0 && controller.walletBalance == 0) {
      return const Scaffold(backgroundColor: Color(0xFFF8F9FA), body: Center(child: CircularProgressIndicator(color: Colors.green)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Softer background
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Colors.green,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Green Header Background
                  Container(
                    height: 220,
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 60),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('My Dashboard', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                        IconButton(onPressed: _onRefresh, icon: const Icon(Icons.refresh, color: Colors.white)),
                      ],
                    ),
                  ),

                  // Main Wallet Card (Overlapping)
                  Positioned(
                    top: 120,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Available Balance', style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text('₹${controller.availableBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.black87, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1)),
                                ],
                              ),
                              Container(
                                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                                padding: const EdgeInsets.all(12),
                                child: const Icon(Icons.account_balance_wallet, color: Colors.green, size: 28),
                              )
                            ],
                          ),
                          if (controller.lockedBalance > 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20)),
                              child: Text('Pending Withdrawal: ₹${controller.lockedBalance.toStringAsFixed(0)}', style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.w600)),
                            )
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: controller.availableBalance > 0 ? () => _showWithdrawDialog(context, controller) : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                disabledBackgroundColor: Colors.grey.shade300,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: const Text('Withdraw Funds', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Spacer for overlapping card
            const SliverToBoxAdapter(child: SizedBox(height: 120)),

            // Period Filters
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      _periodChip('today', 'Today'),
                      _periodChip('week', 'Week'),
                      _periodChip('month', 'Month'),
                      _periodChip('all', 'All'),
                    ],
                  ),
                ),
              ),
            ),

            // Metrics Row (Earnings & Deliveries)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.payments_outlined, color: Colors.blue.shade700, size: 24)),
                            const SizedBox(height: 16),
                            Text('₹${controller.totalEarnings.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 4),
                            Text(_period == 'all' ? 'Total Earnings' : 'Earnings', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.local_shipping_outlined, color: Colors.purple.shade700, size: 24)),
                            const SizedBox(height: 16),
                            Text('${controller.totalDeliveries}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 4),
                            Text('Deliveries', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tab Toggle (Orders vs Ledger)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    _tabButton(title: 'Recent Orders', isActive: !_showStatements, onTap: () => setState(() => _showStatements = false)),
                    const SizedBox(width: 16),
                    _tabButton(title: 'Wallet Ledger', isActive: _showStatements, onTap: () => setState(() => _showStatements = true)),
                  ],
                ),
              ),
            ),

            // Dynamic List
            if (_showStatements) _buildStatementsList(controller) else _buildRecentOrdersList(controller),

            SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 80)),
          ],
        ),
      ),
    );
  }

  // Segmented Control Tab Button
  Widget _tabButton({required String title, required bool isActive, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isActive ? Colors.green : Colors.transparent, width: 3)),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              color: isActive ? Colors.green : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _periodChip(String value, String label) {
    final bool selected = _period == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changePeriod(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black87 : Colors.grey.shade600,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrdersList(EarningsController controller) {
    if (controller.recent.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text("No deliveries in this period", style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final item = controller.recent[index];
          final amount = (item['amount'] ?? 0).toString();
          final title = 'Order #${item['id'] ?? ''}';
          final customer = (item['customer_name'] ?? 'Customer').toString();
          final time = (item['time'] ?? '').toString();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade50,
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                ),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('$customer • $time', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                trailing: Text('+₹$amount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
              ),
            ),
          );
        },
        childCount: controller.recent.length,
      ),
    );
  }

  Widget _buildStatementsList(EarningsController controller) {
    if (controller.statements.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text("No ledger history found", style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final item = controller.statements[index];
          final title = item['title'] ?? 'Transaction';
          final desc = item['description'] ?? '';
          final credit = double.tryParse(item['credit']?.toString() ?? '0') ?? 0;
          final debit = double.tryParse(item['debit']?.toString() ?? '0') ?? 0;
          final date = item['created_at']?.toString() ?? '';

          final isCredit = credit > 0;
          final amountStr = isCredit ? '+₹${credit.toStringAsFixed(0)}' : '-₹${debit.toStringAsFixed(0)}';
          final color = isCredit ? Colors.green : Colors.red.shade600;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: isCredit ? Colors.green.shade50 : Colors.red.shade50,
                  child: Icon(isCredit ? Icons.south_west : Icons.north_east, color: color, size: 18),
                ),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (desc.isNotEmpty) const SizedBox(height: 2),
                    if (desc.isNotEmpty) Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(date, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                  ],
                ),
                trailing: Text(amountStr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
              ),
            ),
          );
        },
        childCount: controller.statements.length,
      ),
    );
  }
}