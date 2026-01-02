import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;

  const SplashScreen({super.key, required this.isLoggedIn});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _iconController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  int _currentPage = 0;
  late PageController _pageController;
  Timer? _pageTimer;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.delivery_dining,
      'title': 'Tiffinity',
      'subtitle': 'Delivery Partner Portal',
      'description': 'Delivering fresh meals, on time',
    },
    {
      'icon': Icons.directions_bike,
      'title': 'Fast Delivery',
      'subtitle': 'Quick & Reliable',
      'description': 'Efficient route planning for faster deliveries',
    },
    {
      'icon': Icons.attach_money,
      'title': 'Earn More',
      'subtitle': 'Flexible Earnings',
      'description': 'Work on your schedule, maximize your income',
    },
  ];

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Pulse animation for logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Progress animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9), // Total splash duration
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _scaleController.forward();
    _progressController.forward();

    // Auto-advance pages
    _pageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPage < _pages.length - 1) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        timer.cancel();
        // Navigate based on login status
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              widget.isLoggedIn ? '/home' : '/login',
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageTimer?.cancel();
    _fadeController.dispose();
    _scaleController.dispose();
    _iconController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade50,
              Colors.white,
              Colors.green.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Background decorative icons
              Expanded(
                child: Stack(
                  children: [
                    // Top left box icon
                    Positioned(
                      top: 40,
                      left: 40,
                      child: AnimatedBuilder(
                        animation: _iconController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: 0.08 + (0.04 * _iconController.value),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 80,
                              color: Colors.green.shade300,
                            ),
                          );
                        },
                      ),
                    ),
                    // Top right location icon
                    Positioned(
                      top: 150,
                      right: 60,
                      child: AnimatedBuilder(
                        animation: _iconController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: 0.12 - (0.04 * _iconController.value),
                            child: Icon(
                              Icons.location_on_outlined,
                              size: 100,
                              color: Colors.green.shade200,
                            ),
                          );
                        },
                      ),
                    ),
                    // Bottom left icons
                    Positioned(
                      bottom: 100,
                      left: 30,
                      child: AnimatedBuilder(
                        animation: _iconController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: 0.08 + (0.03 * _iconController.value),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.pedal_bike_outlined,
                                  size: 90,
                                  color: Colors.green.shade200,
                                ),
                                const SizedBox(width: 20),
                                Icon(
                                  Icons.directions_bike_outlined,
                                  size: 70,
                                  color: Colors.green.shade300,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Bottom right delivery icon
                    Positioned(
                      bottom: 150,
                      right: 40,
                      child: AnimatedBuilder(
                        animation: _iconController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: 0.10 - (0.03 * _iconController.value),
                            child: Icon(
                              Icons.fastfood_outlined,
                              size: 85,
                              color: Colors.green.shade300,
                            ),
                          );
                        },
                      ),
                    ),

                    // Center content
                    Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Glassmorphism container with pulse effect
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Outer glow pulse
                                        Container(
                                          width: 160,
                                          height: 160,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.green.withOpacity(
                                                  0.3 * (2 - _pulseAnimation.value),
                                                ),
                                                blurRadius: 40,
                                                spreadRadius: 15,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Glassmorphism container
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(80),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                            child: Container(
                                              width: 140,
                                              height: 140,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.green.shade600.withOpacity(0.9),
                                                    Colors.green.shade700.withOpacity(0.8),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                border: Border.all(
                                                  color: Colors.white.withOpacity(0.2),
                                                  width: 1.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green.withOpacity(0.4),
                                                    blurRadius: 30,
                                                    spreadRadius: 5,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.delivery_dining,
                                                size: 70,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 35),

                              // PageView for content
                              SizedBox(
                                height: 165,
                                child: PageView.builder(
                                  controller: _pageController,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentPage = index;
                                    });
                                  },
                                  itemCount: _pages.length,
                                  itemBuilder: (context, index) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _pages[index]['title'],
                                          style: TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade800,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _pages[index]['subtitle'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.green.shade600,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // Page indicator dots
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: List.generate(
                                            _pages.length,
                                                (dotIndex) => AnimatedContainer(
                                              duration: const Duration(milliseconds: 300),
                                              margin: const EdgeInsets.symmetric(horizontal: 4),
                                              width: _currentPage == dotIndex ? 24 : 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: _currentPage == dotIndex
                                                    ? Colors.green.shade600
                                                    : Colors.green.shade200,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Flexible(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 40),
                                            child: Text(
                                              _pages[index]['description'],
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Minimal progress indicator at bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 30, left: 50, right: 50),
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _progressController.value,
                            backgroundColor: Colors.green.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green.shade600,
                            ),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
