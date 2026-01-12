// lib/screens/profile/profile_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/locale_provider.dart';
import 'profile_controller.dart';
import 'widgets/profile_header.dart';
import 'widgets/logout_button.dart';
import 'pages/profile_pages.dart';

// ✅ Changed to StatefulWidget
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // ✅ Refresh user data every time profile page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<ProfileController>();
      controller.refreshUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Consumer<ProfileController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              // Green Header Section with Profile Card
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        // Top Bar with Title
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'My Profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  // Settings or Edit action
                                },
                                icon: const Icon(
                                  Icons.settings_outlined,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Profile Header Card (White card inside green section)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: ProfileHeader(controller: controller),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Section Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Account & Settings',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Profile Options
              SliverToBoxAdapter(
                child: _buildProfileOptions(context),
              ),

              // Logout Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 16),
                  child: const LogoutButton(),
                ),
              ),

              // Extra Bottom Padding to avoid bottom nav overlap
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 80,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileOptions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        children: [
          _buildOptionItem(
            context,
            icon: Icons.description,
            title: 'Documents',
            subtitle: 'Aadhaar, License, RC',
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DocumentsPage()),
            ),
          ),
          _buildDivider(),
          _buildOptionItem(
            context,
            icon: Icons.two_wheeler,
            title: 'Vehicle Details',
            subtitle: 'Registration & Insurance',
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VehicleDetailsPage()),
            ),
          ),
          _buildDivider(),
          _buildOptionItem(
            context,
            icon: Icons.account_balance,
            title: 'Bank Details',
            subtitle: 'Account & Payouts',
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BankDetailsPage()),
            ),
          ),
          _buildDivider(),
          _buildOptionItem(
            context,
            icon: Icons.monetization_on,
            title: 'Earnings Summary',
            subtitle: 'Total earnings & stats',
            color: Colors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EarningsSummaryPage()),
            ),
          ),
          _buildDivider(),
          _buildOptionItem(
            context,
            icon: Icons.bar_chart,
            title: 'Delivery Stats',
            subtitle: 'Performance & ratings',
            color: Colors.teal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeliveryStatsPage()),
            ),
          ),
          _buildDivider(),
          _buildOptionItem(
            context,
            icon: Icons.settings,
            title: 'Account Settings',
            subtitle: 'Email & Phone verification',
            color: Colors.blueGrey,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
            ),
          ),
          _buildDivider(),
          _buildOptionItem(
            context,
            icon: Icons.access_time,
            title: 'Availability',
            subtitle: 'Set active hours',
            color: Colors.indigo,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AvailabilityPage()),
            ),
          ),
          _buildDivider(),
          _buildOptionItem(
            context,
            icon: Icons.language,
            title: 'Language',
            subtitle: _getCurrentLanguageName(context),
            color: Colors.deepOrange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LanguagePage()),
            ),
          ),
          _buildDivider(),
          _buildOptionItem(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage alerts',
            color: Colors.pink,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            ),
          ),
          _buildDivider(),
          _buildOptionItem(
            context,
            icon: Icons.help,
            title: 'Help Center',
            subtitle: 'FAQs & support',
            color: Colors.cyan,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpCenterPage()),
            ),
          ),
          _buildDivider(),
          _buildOptionItem(
            context,
            icon: Icons.contact_support,
            title: 'Contact Support',
            subtitle: 'Get help',
            color: Colors.deepPurple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactSupportPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 54,
      endIndent: 16,
      color: Colors.grey[200],
    );
  }

  String _getCurrentLanguageName(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    switch (locale.languageCode) {
      case 'hi':
        return 'हिन्दी';
      case 'mr':
        return 'मराठी';
      case 'gu':
        return 'ગુજરાતી';
      case 'ta':
        return 'தமிழ்';
      case 'te':
        return 'తెలుగు';
      case 'kn':
        return 'ಕನ್ನಡ';
      case 'ml':
        return 'മലയാളം';
      case 'bn':
        return 'বাংলা';
      case 'pa':
        return 'ਪੰਜਾਬੀ';
      default:
        return 'English';
    }
  }
}
