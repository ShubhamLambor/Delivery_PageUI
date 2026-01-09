// lib/screens/profile/pages/profile_pages.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/locale_provider.dart';
import '../profile_controller.dart';
import '../verification/otp_verification_page.dart';

// ==============================================================================
//  1. DOCUMENTS PAGE (Status Cards)
// ==============================================================================

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, 'Documents'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDocCard(
            title: 'Aadhaar Card',
            status: 'Verified',
            color: Colors.green,
            icon: Icons.badge,
            lastUpdated: 'Updated 2 months ago',
          ),
          _buildDocCard(
            title: 'Driving License',
            status: 'Verified',
            color: Colors.green,
            icon: Icons.directions_car,
            lastUpdated: 'Expires in 2028',
          ),
          _buildDocCard(
            title: 'PAN Card',
            status: 'Pending Verification',
            color: Colors.orange,
            icon: Icons.account_balance_wallet,
            lastUpdated: 'Uploaded yesterday',
          ),
          _buildDocCard(
            title: 'Vehicle Insurance',
            status: 'Expired',
            color: Colors.red,
            icon: Icons.health_and_safety,
            lastUpdated: 'Expired on Dec 31, 2025',
            showAction: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard({
    required String title,
    required String status,
    required Color color,
    required IconData icon,
    required String lastUpdated,
    bool showAction = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(lastUpdated, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
              if (showAction) ...[
                const SizedBox(height: 8),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ]
            ],
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
//  2. VEHICLE DETAILS PAGE (Digital RC Card Style)
// ==============================================================================

class VehicleDetailsPage extends StatelessWidget {
  const VehicleDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, 'Vehicle Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Vehicle Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.two_wheeler, color: Colors.white, size: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Active', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('MH 04 AB 1234', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text('Honda Activa 6G • Petrol', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildVehicleMeta('Model Year', '2023'),
                      _buildVehicleMeta('Color', 'Matte Grey'),
                      _buildVehicleMeta('Fuel', 'Full Tank'),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Specs / Info List
            _buildDetailTile(Icons.branding_watermark, 'Chassis Number', 'MBH123...890'),
            _buildDetailTile(Icons.speed, 'Max Speed', '85 km/h'),
            _buildDetailTile(Icons.health_and_safety, 'Insurance Policy', 'HDFC Ergo • Valid till 2026'),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleMeta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ==============================================================================
//  3. BANK DETAILS PAGE (Credit Card Style)
// ==============================================================================

class BankDetailsPage extends StatelessWidget {
  const BankDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, 'Bank Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4527A0), Color(0xFF7E57C2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.account_balance, color: Colors.white, size: 28),
                      Text('PRIMARY', style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text('XXXX XXXX XXXX 8921', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Card Holder', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                          const SizedBox(height: 4),
                          const Text('RAJESH KUMAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('IFSC Code', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
                          const SizedBox(height: 4),
                          const Text('HDFC0001234', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailTile(Icons.history, 'Payout History', 'View last 6 months transactions'),
            _buildDetailTile(Icons.settings, 'Payout Settings', 'Weekly settlements (Every Monday)'),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
//  4. EARNINGS SUMMARY PAGE (Green Design)
// ==============================================================================

class EarningsSummaryPage extends StatefulWidget {
  const EarningsSummaryPage({super.key});

  @override
  State<EarningsSummaryPage> createState() => _EarningsSummaryPageState();
}

class _EarningsSummaryPageState extends State<EarningsSummaryPage> {
  String selectedFilter = 'All Time';
  final List<String> filters = ['All Time', 'This Month', 'This Week', 'Today'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, 'Earnings Summary'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF43A047)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Text('Total Earnings', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  const Text('₹ 1536.00', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSummaryMetric('15', 'Deliveries', Icons.electric_bike),
                        VerticalDivider(color: Colors.white.withOpacity(0.3), thickness: 1),
                        _buildSummaryMetric('₹102', 'Avg/Delivery', Icons.trending_up),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((filter) {
                  final isSelected = selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        if (selected) setState(() => selectedFilter = filter);
                      },
                      selectedColor: const Color(0xFF4CAF50),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w500),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('All Deliveries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text('15 orders', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ]),
            const SizedBox(height: 12),
            _buildDeliveryItem('#DEL1001', 'Rajesh Kumar', '123 MG Road, Mumbai', 'Jan 03 • 09:23 AM', '85.50', '3.5 km', true),
            _buildDeliveryItem('#DEL1002', 'Priya Sharma', '456 Linking Road, Bandra', 'Jan 03 • 06:23 AM', '120.00', '5.2 km', true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(String value, String label, IconData icon) {
    return Column(children: [Icon(icon, color: Colors.white, size: 20), const SizedBox(height: 6), Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 2), Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12))]);
  }

  Widget _buildDeliveryItem(String orderId, String name, String address, String time, String price, String distance, bool isDelivered) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.green.withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.shopping_bag, color: Colors.green, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Order $orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), const SizedBox(height: 4), Text(name, style: TextStyle(color: Colors.grey[600], fontSize: 13))])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('₹ $price', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)), const SizedBox(height: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(isDelivered ? 'Delivered' : 'Pending', style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)))])
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),
          Row(children: [Icon(Icons.location_on, size: 14, color: Colors.grey[600]), const SizedBox(width: 4), Expanded(child: Text(address, style: TextStyle(fontSize: 12, color: Colors.grey[700]), maxLines: 1, overflow: TextOverflow.ellipsis))]),
          const SizedBox(height: 8),
          Row(children: [Icon(Icons.access_time, size: 14, color: Colors.grey[500]), const SizedBox(width: 4), Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[500])), const Spacer(), Icon(Icons.local_shipping, size: 14, color: Colors.grey[600]), const SizedBox(width: 4), Text(distance, style: TextStyle(fontSize: 12, color: Colors.grey[600]))])
        ],
      ),
    );
  }
}

// ==============================================================================
//  5. DELIVERY STATS PAGE (Dashboard Grid)
// ==============================================================================

class DeliveryStatsPage extends StatelessWidget {
  const DeliveryStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, 'Delivery Stats'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildStatCard('Total Orders', '142', Icons.local_shipping, Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('On Time', '98%', Icons.timer, Colors.green)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('Rating', '4.8', Icons.star, Colors.amber)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Cancelled', '2', Icons.cancel, Colors.red)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weekly Performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                      return Column(
                        children: [
                          Container(width: 8, height: 60 + (day.length * 10.0), decoration: BoxDecoration(color: day == 'Fri' ? Colors.green : Colors.grey[200], borderRadius: BorderRadius.circular(4))),
                          const SizedBox(height: 8),
                          Text(day, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                        ],
                      );
                    }).toList(),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
}

// ==============================================================================
//  6. ACCOUNT SETTINGS PAGE (Email & Phone Verification)
// ==============================================================================

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: _buildAppBar(context, 'Account Settings'),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Email Verification Card
              _buildVerificationCard(
                context: context,
                icon: Icons.email_outlined,
                title: 'Email Address',
                value: controller.email.isNotEmpty ? controller.email : 'Not added',
                isVerified: controller.isEmailVerified,
                channel: 'Email',
                color: Colors.blue,
                onVerify: () async {
                  if (controller.email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please add your email first'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OtpVerificationPage(
                        channel: 'Email',
                        destination: controller.email,
                      ),
                    ),
                  );

                  if (result == true) {
                    controller.markEmailVerified();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email verified successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                onEdit: () async {
                  final newEmail = await _showEditDialog(
                    context,
                    title: 'Update Email',
                    currentValue: controller.email,
                    hint: 'Enter email address',
                    keyboardType: TextInputType.emailAddress,
                  );

                  if (newEmail != null && newEmail.trim().isNotEmpty) {
                    await controller.updateEmail(newEmail.trim());
                  }
                },
              ),

              const SizedBox(height: 16),

              // Phone Verification Card
              _buildVerificationCard(
                context: context,
                icon: Icons.phone_iphone,
                title: 'Mobile Number',
                value: controller.phone.isNotEmpty ? controller.phone : 'Not added',
                isVerified: controller.isPhoneVerified,
                channel: 'Phone',
                color: Colors.teal,
                onVerify: () async {
                  if (controller.phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please add your phone number first'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OtpVerificationPage(
                        channel: 'Phone',
                        destination: controller.phone,
                      ),
                    ),
                  );

                  if (result == true) {
                    controller.markPhoneVerified();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Phone number verified successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                onEdit: () async {
                  final newPhone = await _showEditDialog(
                    context,
                    title: 'Update Phone',
                    currentValue: controller.phone,
                    hint: 'Enter phone number',
                    keyboardType: TextInputType.phone,
                  );

                  if (newPhone != null && newPhone.trim().isNotEmpty) {
                    await controller.updatePhone(newPhone.trim());
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVerificationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required bool isVerified,
    required String channel,
    required Color color,
    required VoidCallback onVerify,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isVerified ? null : onVerify,
                  icon: Icon(
                    isVerified ? Icons.check_circle : Icons.verified_user,
                    size: 16,
                  ),
                  label: Text(isVerified ? 'Verified' : 'Verify'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isVerified ? Colors.grey : color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<String?> _showEditDialog(
      BuildContext context, {
        required String title,
        required String currentValue,
        required String hint,
        required TextInputType keyboardType,
      }) {
    final controller = TextEditingController(text: currentValue);

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
//  7. OTHER SETTINGS & SUPPORT PAGES
// ==============================================================================

class AvailabilityPage extends StatefulWidget {
  const AvailabilityPage({super.key});
  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  bool isOnline = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, 'Availability'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Active Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(isOnline ? 'You are visible to orders' : 'You are offline', style: TextStyle(color: isOnline ? Colors.green : Colors.grey, fontSize: 13)),
                ],
              ),
              Switch(value: isOnline, activeColor: Colors.green, onChanged: (val) => setState(() => isOnline = val)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('  Shift Schedule', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        _buildSettingsTile(Icons.sunny, 'Morning Shift', '08:00 AM - 02:00 PM'),
        _buildSettingsTile(Icons.nightlight_round, 'Evening Shift', '06:00 PM - 11:00 PM'),
      ]),
    );
  }
}

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  final List<Map<String, String>> languages = const [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिंदी'},
    {'code': 'mr', 'name': 'Marathi', 'nativeName': 'मराठी'},
    {'code': 'gu', 'name': 'Gujarati', 'nativeName': 'ગુજરાતી'},
    {'code': 'ta', 'name': 'Tamil', 'nativeName': 'தமிழ்'},
    {'code': 'te', 'name': 'Telugu', 'nativeName': 'తెలుగు'},
    {'code': 'kn', 'name': 'Kannada', 'nativeName': 'ಕನ್ನಡ'},
    {'code': 'ml', 'name': 'Malayalam', 'nativeName': 'മലയാളം'},
    {'code': 'bn', 'name': 'Bengali', 'nativeName': 'বাংলা'},
    {'code': 'pa', 'name': 'Punjabi', 'nativeName': 'ਪੰਜਾਬੀ'},
  ];

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Select Language', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final language = languages[index];
          final isSelected = localeProvider.locale.languageCode == language['code'];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: Colors.green, width: 2) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              onTap: () async {
                await localeProvider.setLocale(Locale(language['code']!));

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Language changed to ${language['name']}'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.language,
                  color: isSelected ? Colors.green : Colors.grey[600],
                  size: 24,
                ),
              ),
              title: Text(
                language['nativeName']!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.green : Colors.black87,
                ),
              ),
              subtitle: Text(
                language['name']!,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
                  : const Icon(Icons.chevron_right, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        },
      ),
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, 'Notifications'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _buildSwitchTile('New Orders', 'Get alerts for new deliveries', true),
        _buildSwitchTile('Promotions', 'Receive offers and bonus updates', false),
        _buildSwitchTile('App Updates', 'Get notified about app features', true),
      ]),
    );
  }
  Widget _buildSwitchTile(String title, String subtitle, bool value) {
    return Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: SwitchListTile(value: value, onChanged: (v) {}, activeColor: Colors.green, title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600]))));
  }
}

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, 'Help Center'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: const TextField(decoration: InputDecoration(border: InputBorder.none, hintText: 'Search for issues...', icon: Icon(Icons.search, color: Colors.grey)))),
        const SizedBox(height: 20),
        const Text('  Common Issues', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        _buildSettingsTile(Icons.payment, 'Payment Issue', 'Payouts, Earnings, Bonus'),
        _buildSettingsTile(Icons.person, 'Account & Profile', 'Update details, Documents'),
        _buildSettingsTile(Icons.delivery_dining, 'Order Issues', 'Pickup, Drop-off, Location'),
      ]),
    );
  }
}

class ContactSupportPage extends StatelessWidget {
  const ContactSupportPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, 'Contact Support'),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _buildContactCard(Icons.headset_mic, 'Customer Care', 'Talk to our support executive', 'Call Now', Colors.blue),
        _buildContactCard(Icons.chat, 'Chat Support', 'Chat with us for quick help', 'Start Chat', Colors.green),
        _buildContactCard(Icons.email, 'Email Support', 'Get help via email', 'Send Email', Colors.orange),
      ]),
    );
  }
  Widget _buildContactCard(IconData icon, String title, String subtitle, String btnText, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 30)),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(side: BorderSide(color: color), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: Text(btnText, style: TextStyle(color: color))))
      ]),
    );
  }
}

// ==============================================================================
//  COMMON HELPERS
// ==============================================================================

PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
  return AppBar(
    title: Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
    backgroundColor: Colors.white,
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.black),
    leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
  );
}

Widget _buildDetailTile(IconData icon, String title, String subtitle) {
  return Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.black87)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12))));
}

Widget _buildSettingsTile(IconData icon, String title, String subtitle) {
  return Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: ListTile(leading: Icon(icon, color: Colors.grey[700]), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)), subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])), trailing: const Icon(Icons.chevron_right, color: Colors.grey)));
}
