// lib/screens/nav/bottom_nav.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // REQUIRED FOR SystemNavigator.pop()
import 'package:provider/provider.dart';

import '../home/home_page.dart';
import '../deliveries/deliveries_page.dart';
import '../earnings/earnings_page.dart';
import 'nav_controller.dart';
import '../auth/auth_controller.dart';
import '../kyc/kyc_popup_dialog.dart';
import 'package:TiffinityGo/screens/profile/profile_page.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  static bool _hasShownKycPopup = false;
  DateTime? _lastBackPressTime; // ADDED FOR DOUBLE-TAP LOGIC

  final List<Widget> _pages = [
    const HomePage(),
    const DeliveriesPage(),
    const EarningsPage(),
    const ProfilePage(),
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
        // WRAP SCAFFOLD IN POPSCOPE HERE
        return PopScope(
          canPop: false, // Prevents immediate exit
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            // 1. If NOT on the Home tab (index 0), switch to Home tab
            if (nav.currentIndex != 0) {
              nav.changeTab(0);
              return;
            }

            // 2. Double-tap to exit logic for the Home tab
            final now = DateTime.now();
            if (_lastBackPressTime == null ||
                now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {

              _lastBackPressTime = now;

              // CLEAR any existing snackbars first so they don't stack up
              ScaffoldMessenger.of(context).hideCurrentSnackBar();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  elevation: 0, // Remove default shadow
                  behavior: SnackBarBehavior.floating, // Make it float above the UI
                  backgroundColor: Colors.transparent, // Make the default background invisible
                  margin: const EdgeInsets.only(bottom: 110, left: 32, right: 32), // Position it above the BottomNav
                  content: ClipRRect(
                    borderRadius: BorderRadius.circular(25), // Smooth rounded corners
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // The glass blur
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        decoration: BoxDecoration(
                          // Match your bottom nav gradient
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.9),
                              Colors.white.withOpacity(0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8), // Crisp white border
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.exit_to_app_rounded,
                              color: Colors.grey.shade800, // Dark grey to contrast with the light glass
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Press back again to exit',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            } else {
              // Reliably closes the app
              SystemNavigator.pop();
            }
          },
          child: Scaffold(
            extendBody: true,
            body: _pages[nav.currentIndex],
            bottomNavigationBar: _buildShinyGlassNav(context, nav),
          ),
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
              color: Colors.black.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: Colors.white.withOpacity(0.8),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
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
                              colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
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
                color: isSelected ? Colors.white : Colors.grey.shade700,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}