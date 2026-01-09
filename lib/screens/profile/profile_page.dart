// lib/screens/profile/profile_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../auth/login_page.dart';
import '../kyc/kyc_popup_dialog.dart';
import 'profile_controller.dart';
import 'pages/profile_pages.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Get the AuthController (Source of Truth for User Data)
    final authController = Provider.of<AuthController>(context);
    final user = authController.user;

    // 2. Check for KYC status using the correct user object
    final bool isKycPending = user != null &&
        (user.vehicleNumber == null || user.vehicleNumber!.isEmpty);

    // 3. Get display name from Auth User
    final String displayName = user?.name ?? 'Delivery Partner';

    return Consumer<ProfileController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8F9FA),
            body: Center(child: CircularProgressIndicator(color: Colors.green)),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // --- 1. Custom Green Header with Profile Photo ---
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Gradient Background
                    Container(
                      height: 260,
                      width: double.infinity,
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
                    ),

                    // Header Content
                    Positioned(
                      top: 60,
                      child: Column(
                        children: [
                          const Text(
                              'My Profile',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                            child: const Text('Member since Dec 2025', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),

                    // Floating Profile Card
                    Positioned(
                      top: 140,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage: (user?.profilePic != null && user!.profilePic.isNotEmpty)
                                      ? NetworkImage(user.profilePic)
                                      : (controller.profilePhotoUrl != null ? NetworkImage(controller.profilePhotoUrl!) : null),
                                  backgroundColor: Colors.grey[200],
                                  child: (user?.profilePic == null || user!.profilePic.isEmpty) && controller.profilePhotoUrl == null
                                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => controller.changeProfilePhoto(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Display Name
                            Text(
                              displayName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('Mumbai, India', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              ],
                            ),

                            // Verification Status Badge (Optional)
                            if (user != null && user.hasAnyVerification) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: user.isFullyVerified ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      user.isFullyVerified ? Icons.verified : Icons.verified_user,
                                      size: 14,
                                      color: user.isFullyVerified ? Colors.green : Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      user.verificationStatus,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: user.isFullyVerified ? Colors.green : Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () async {
                                  final newName = await _askName(context, displayName);
                                  if (newName != null && newName.trim().isNotEmpty) {
                                    await controller.updateName(newName.trim());
                                    // Optionally reload AuthController user here
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  side: BorderSide(color: Colors.green.shade400),
                                ),
                                child: Text('Edit Profile', style: TextStyle(color: Colors.green.shade700)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 120),

                // --- 2. Main Menu Options ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KYC Alert
                      if (isKycPending) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('KYC Pending', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                    const SizedBox(height: 4),
                                    Text('Verify to unlock full access', style: TextStyle(fontSize: 12, color: Colors.green.shade800)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(context: context, builder: (ctx) => const KYCPopupDialog());
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                ),
                                child: const Text('Verify'),
                              )
                            ],
                          ),
                        ),
                      ],

                      // Account Section
                      _buildSectionHeader('Account'),
                      _buildMenuItem(
                        context,
                        icon: Icons.description,
                        title: 'Documents',
                        onTap: () => _open(context, const DocumentsPage()),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.electric_bike,
                        title: 'Vehicle Details',
                        onTap: () => _open(context, const VehicleDetailsPage()),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.account_balance,
                        title: 'Bank Details',
                        onTap: () => _open(context, const BankDetailsPage()),
                      ),

                      const SizedBox(height: 24),

                      // Performance Section
                      _buildSectionHeader('Performance'),
                      _buildMenuItem(
                        context,
                        icon: Icons.currency_rupee,
                        title: 'Earnings Summary',
                        onTap: () => _open(context, const EarningsSummaryPage()),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.bar_chart,
                        title: 'Delivery Stats',
                        onTap: () => _open(context, const DeliveryStatsPage()),
                      ),

                      const SizedBox(height: 24),

                      // Settings Section
                      _buildSectionHeader('Settings'),

                      // ✅ NEW: Account Settings with verification badge
                      _buildMenuItem(
                        context,
                        icon: Icons.security,
                        title: 'Account Settings',
                        subtitle: _buildVerificationSubtitle(user),
                        showBadge: user != null && !user.isFullyVerified,
                        onTap: () => _open(context, const AccountSettingsPage()),
                      ),

                      _buildMenuItem(
                        context,
                        icon: Icons.schedule,
                        title: 'Availability',
                        onTap: () => _open(context, const AvailabilityPage()),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.language,
                        title: 'Language',
                        onTap: () => _open(context, const LanguagePage()),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.notifications,
                        title: 'Notifications',
                        onTap: () => _open(context, const NotificationsPage()),
                      ),

                      const SizedBox(height: 24),

                      // Support Section
                      _buildSectionHeader('Support'),
                      _buildMenuItem(
                        context,
                        icon: Icons.help_center,
                        title: 'Help Center',
                        onTap: () => _open(context, const HelpCenterPage()),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.contact_support,
                        title: 'Contact Support',
                        onTap: () => _open(context, const ContactSupportPage()),
                      ),

                      const SizedBox(height: 32),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () async {
                            final confirmed = await _showLogoutDialog(context);
                            if (confirmed == true) {
                              await authController.logout();
                              await controller.logout();
                              if (!context.mounted) return;
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const LoginPage()),
                                    (route) => false,
                              );
                            }
                          },
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text(
                            'Log Out',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.red.shade50,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Helper: Build verification subtitle ---
  String _buildVerificationSubtitle(dynamic user) {
    if (user == null) return 'Email & Phone verification';

    if (user.isFullyVerified) {
      return 'Fully verified ✓';
    } else if (user.hasAnyVerification) {
      return 'Verification pending';
    } else {
      return 'Not verified';
    }
  }

  // --- Helpers ---
  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        String? subtitle,
        bool showBadge = false,
        required VoidCallback onTap,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.green.shade700, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showBadge)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<String?> _askName(BuildContext context, String current) {
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

  Future<bool?> _showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
