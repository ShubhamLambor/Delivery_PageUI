import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    await Future.delayed(const Duration(milliseconds: 2000));

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        isLoggedIn ? '/home' : '/login',
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // ✅ Matches your app's green gradient
          gradient: LinearGradient(
            colors: [
              const Color(0xFF4CAF50), // Primary green from your app
              const Color(0xFF66BB6A), // Lighter green
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Tiffin Box Stack
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Transform.rotate(
                        angle: _rotateAnimation.value,
                        child: _buildTiffinStack(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // App Title - white for contrast on green
                const Text(
                  'Tiffinity',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Delivery Partner Portal',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant,
                      size: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fresh meals, delivered fast',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),

                // Loading indicator - white on green
                const SizedBox(
                  width: 35,
                  height: 35,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Custom Tiffin Stack Widget - Green & White theme
  Widget _buildTiffinStack() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Shadow
        Positioned(
          bottom: -10,
          child: Container(
            width: 140,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(70),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 30,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
        ),

        // Tiffin Stack
        SizedBox(
          width: 140,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Handle on top - Metallic silver/white
              Positioned(
                top: 0,
                child: _buildTiffinHandle(),
              ),

              // Top Layer (Light Green)
              Positioned(
                top: 20,
                child: _buildTiffinLayer(
                  const Color(0xFF66BB6A), // Light green
                  const Color(0xFF81C784), // Lighter green
                  30,
                  isTop: true,
                ),
              ),

              // Middle Layer (Primary Green)
              Positioned(
                top: 50,
                child: _buildTiffinLayer(
                  const Color(0xFF4CAF50), // Primary green
                  const Color(0xFF66BB6A), // Light green
                  35,
                ),
              ),

              // Bottom Layer (Dark Green)
              Positioned(
                top: 85,
                child: _buildTiffinLayer(
                  const Color(0xFF388E3C), // Dark green
                  const Color(0xFF4CAF50), // Primary green
                  40,
                  isBottom: true,
                ),
              ),

              // Delivery bike icon overlay - white badge
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.delivery_dining,
                    size: 24,
                    color: Color(0xFF4CAF50), // Primary green
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Tiffin Handle - Metallic gray/white
  Widget _buildTiffinHandle() {
    return Container(
      width: 50,
      height: 25,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          width: 3.5,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(25),
        ),
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  // Individual Tiffin Layer - Green shades
  Widget _buildTiffinLayer(
      Color topColor,
      Color bottomColor,
      double height, {
        bool isTop = false,
        bool isBottom = false,
      }) {
    return Container(
      width: 100,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [topColor, bottomColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(
          top: isTop ? const Radius.circular(8) : Radius.zero,
          bottom: isBottom ? const Radius.circular(12) : Radius.zero,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          // Metallic shine effect - white highlight
          Positioned(
            left: 10,
            top: height * 0.25,
            child: Container(
              width: 3,
              height: height * 0.5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Horizontal lines for texture
          if (!isTop)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                color: Colors.black.withOpacity(0.2),
              ),
            ),
          // Bottom edge highlight for depth
          if (!isBottom)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
