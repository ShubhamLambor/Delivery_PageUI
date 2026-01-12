import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // ✅ Add this import
import '../profile_controller.dart';

class ProfileHeader extends StatelessWidget {
  final ProfileController controller;

  const ProfileHeader({super.key, required this.controller});

  // ✅ Helper method to format registration date
  String _formatRegistrationDate(DateTime? date) {
    if (date == null) return 'Member since Jan 2024';

    final formatter = DateFormat('MMM yyyy');
    return 'Member since ${formatter.format(date)}';
  }

  @override
  Widget build(BuildContext context) {
    final String name = controller.name.isNotEmpty ? controller.name : 'Delivery Partner';
    final String? imageUrl = controller.profilePhotoUrl;

    ImageProvider avatarProvider;
    if (imageUrl == null || imageUrl.isEmpty) {
      avatarProvider = const AssetImage('assets/default_avatar.png');
    } else if (imageUrl.startsWith('http')) {
      avatarProvider = NetworkImage(imageUrl);
    } else {
      avatarProvider = FileImage(File(imageUrl));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with Camera Button
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: avatarProvider,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => controller.changeProfilePhoto(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name with Verification Badge
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Verification Badge
                    if (controller.isEmailVerified || controller.isPhoneVerified)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              color: Colors.green,
                              size: 12,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),

                // Registration Date - ✅ Now Dynamic
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 11,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatRegistrationDate(controller.registrationDate), // ✅ Dynamic
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Phone Number with Verification
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 11,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        controller.phone.isNotEmpty
                            ? controller.phone
                            : '6586461664',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (controller.isPhoneVerified)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 12,
                      ),
                  ],
                ),

                // Email with Verification (if available)
                if (controller.email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.email,
                        size: 11,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          controller.email,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (controller.isEmailVerified)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 12,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
