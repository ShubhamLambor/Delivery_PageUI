// lib/screens/kyc/kyc_popup_dialog.dart

import 'package:flutter/material.dart';
import 'kyc_page.dart';
import '../../data/repository/user_repository.dart'; // ✅ Import repository

class KYCPopupDialog extends StatelessWidget {
  const KYCPopupDialog({super.key}); // ✅ No userId needed

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                    Icons.verified_user,
                    size: 48,
                    color: Colors.green
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Complete Partner KYC',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Verify your identity and vehicle details to start accepting delivery orders and earning.',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Benefits
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _benefitItem(
                        icon: Icons.check_circle,
                        title: 'Verified Account',
                        description: 'Build trust with customers'
                    ),
                    const SizedBox(height: 12),
                    _benefitItem(
                        icon: Icons.trending_up,
                        title: 'Higher Earnings',
                        description: 'Get access to premium deliveries'
                    ),
                    const SizedBox(height: 12),
                    _benefitItem(
                        icon: Icons.lock,
                        title: 'Secure Transactions',
                        description: 'Protected payments and data'
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const KYCPage(), // ✅ No userId needed
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)
                    ),
                  ),
                  child: const Text(
                      'Start KYC Now',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white
                      )
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)
                    ),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: const Text(
                      'Do It Later',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey
                      )
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _benefitItem({
    required IconData icon,
    required String title,
    required String description
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87
                  )
              ),
              Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])
              ),
            ],
          ),
        ),
      ],
    );
  }
}
