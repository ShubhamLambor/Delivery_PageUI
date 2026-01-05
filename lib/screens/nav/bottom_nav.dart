// lib/screens/nav/bottom_nav.dart

import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home/home_page.dart';
import '../deliveries/deliveries_page.dart';
import '../earnings/earnings_page.dart';
import '../profile/profile_page.dart';
import 'nav_controller.dart';
import '../auth/auth_controller.dart';
import '../kyc/kyc_popup_dialog.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  static bool _hasShownKycPopup = false;

  final List<Widget> _pages = const [
    HomePage(),
    DeliveriesPage(),
    EarningsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    if (!_hasShownKycPopup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkKycStatus();
      });
    }
  }

  void _checkKycStatus() {
    final authController = Provider.of<AuthController>(context, listen: false);
    final user = authController.user;

    final bool isKycPending = user != null &&
        (user.vehicleNumber == null || user.vehicleNumber!.isEmpty);

    if (isKycPending) {
      _hasShownKycPopup = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const KYCPopupDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavController>(
      builder: (context, nav, _) {
        return Scaffold(
          extendBody: true,
          body: _pages[nav.currentIndex],
          bottomNavigationBar: _buildShinyGlassNav(context, nav),
        );
      },
    );
  }

  Widget _buildShinyGlassNav(BuildContext context, NavController nav) {
    const int itemCount = 4;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15), // Deep shadow for depth
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Strong Blur
            child: Container(
              decoration: BoxDecoration(
                // THE SHINY GLASS GRADIENT
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.9), // Top is brighter (Light source)
                    Colors.white.withOpacity(0.6), // Bottom is more transparent
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(35),
                // THE CRISP WHITE BORDER
                border: Border.all(
                  color: Colors.white.withOpacity(0.8), // Semi-transparent white border
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  // 1. FLUID INDICATOR
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.fastLinearToSlowEaseIn,
                    alignment: Alignment(
                      -1.0 + (nav.currentIndex / (itemCount - 1)) * 2.0,
                      0,
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 1 / itemCount,
                      child: Center(
                        child: Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF43A047), Color(0xFF1B5E20)], // Green Gradient
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.5),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. ICONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildIconItem(nav, 0, Icons.home_outlined, Icons.home_rounded),
                      _buildIconItem(nav, 1, Icons.delivery_dining_outlined, Icons.delivery_dining),
                      _buildIconItem(nav, 2, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet),
                      _buildIconItem(nav, 3, Icons.person_outline, Icons.person),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconItem(NavController nav, int index, IconData icon, IconData activeIcon) {
    final bool isSelected = nav.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => nav.changeTab(index),
        child: SizedBox(
          height: 72,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) {
                return ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child));
              },
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey<bool>(isSelected),
                color: isSelected ? Colors.white : Colors.grey.shade700, // Darker grey for contrast on glass
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
