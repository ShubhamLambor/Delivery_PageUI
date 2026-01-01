import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'home_controller.dart';
import '../../screens/home/widgets/current_delivery_card.dart';
import '../../screens/home/widgets/stats_card.dart';
import '../../models/delivery_model.dart';
import 'widgets/upcoming_tile.dart';
import '../auth/auth_controller.dart';
import '../map/osm_navigation_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Request location permission when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermission();
    });
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _showLocationServiceDialog();
      }
      return;
    }

    // Check permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          _showPermissionDeniedDialog();
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showPermissionPermanentlyDeniedDialog();
      }
      return;
    }

    // Permission granted
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      debugPrint("Location permission granted");
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Please enable location services to track deliveries.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location access to track your delivery routes and provide accurate navigation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestLocationPermission();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Denied'),
        content: const Text(
          'Location permission is permanently denied. Please enable it from app settings to use delivery tracking features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Geolocator.openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToMess() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OSMNavigationScreen(
          destinationLat: 19.0760,
          destinationLng: 72.8777,
          destinationName: 'Shree Kitchen',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final auth = context.watch<AuthController>();

    final DeliveryModel? current = home.currentDelivery;
    final List<DeliveryModel> upcoming = home.upcomingDeliveries;

    final total = home.totalCount;
    final completed = home.completedCount;
    final pending = home.pendingCount;
    final cancelled = home.cancelledCount;
    final isOnline = home.isOnline;

    final userName = auth.user?.name ?? 'Delivery Partner';

    // Get current date and time
    final now = DateTime.now();
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final currentDate = dateFormat.format(now);
    final currentTime = timeFormat.format(now);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Delivery Boy',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications, color: Colors.black),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Share'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.lightBlueAccent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currentDate,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currentTime,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Swipe Toggle Button
            SwipeToggleButton(
              isOnline: isOnline,
              onToggle: home.toggleOnline,
            ),

            const SizedBox(height: 16),

            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.8,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatsCard(
                  title: 'Total Deliveries Today',
                  value: '$total',
                  icon: Icons.local_shipping,
                  color: Colors.blue,
                ),
                StatsCard(
                  title: 'Completed',
                  value: '$completed',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                StatsCard(
                  title: 'Pending',
                  value: '$pending',
                  icon: Icons.access_time,
                  color: Colors.orange,
                ),
                const StatsCard(
                  title: 'Today\'s Earnings',
                  value: '₹320',
                  icon: Icons.currency_rupee,
                  color: Colors.purple,
                ),
                StatsCard(
                  title: 'Order Cancelled',
                  value: '$cancelled',
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Current Delivery
            if (current != null) ...[
              CurrentDeliveryCard(delivery: current),
              const SizedBox(height: 16),
            ],

            // Pickup Section
            _buildPickupSection(),

            const SizedBox(height: 16),

            // Upcoming Deliveries Section
            _buildUpcomingSection(upcoming),
          ],
        ),
      ),
    );
  }

  // ---- PICKUP SECTION ----
  Widget _buildPickupSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 30),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.store, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Pickup Point',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Shree Kitchen',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '25 Tiffins Ready',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: const [
                Icon(Icons.access_time, color: Colors.orange, size: 14),
                SizedBox(width: 6),
                Text(
                  'Pickup: 10:15 - 10:45 AM',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _navigateToMess,
            icon: const Icon(Icons.navigation),
            label: const Text('Navigate to Mess'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }

  // ---- UPCOMING SECTION ----
  Widget _buildUpcomingSection(List<DeliveryModel> upcoming) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 30),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Deliveries',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${upcoming.length} pending',
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: upcoming.map((d) => UpcomingTile(delivery: d)).toList(),
          ),
        ],
      ),
    );
  }
}

// ---- SWIPE TOGGLE BUTTON WIDGET ----
class SwipeToggleButton extends StatefulWidget {
  final bool isOnline;
  final VoidCallback onToggle;

  const SwipeToggleButton({
    super.key,
    required this.isOnline,
    required this.onToggle,
  });

  @override
  State<SwipeToggleButton> createState() => _SwipeToggleButtonState();
}

class _SwipeToggleButtonState extends State<SwipeToggleButton> {
  double _dragPosition = 0.0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width - 32;
    final trackWidth = screenWidth;
    final thumbWidth = screenWidth / 2 - 4;
    final maxDrag = trackWidth - thumbWidth - 4;

    final targetPosition = widget.isOnline ? maxDrag : 0.0;
    final currentPosition = _isDragging ? _dragPosition : targetPosition;

    return Container(
      height: 50,
      width: trackWidth,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    'Offline',
                    style: TextStyle(
                      color: !widget.isOnline ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Online',
                    style: TextStyle(
                      color: widget.isOnline ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          AnimatedPositioned(
            duration: _isDragging
                ? Duration.zero
                : const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: currentPosition + 2,
            top: 2,
            child: GestureDetector(
              onHorizontalDragStart: (details) {
                setState(() {
                  _isDragging = true;
                  _dragPosition = targetPosition;
                });
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragPosition = (_dragPosition + details.delta.dx)
                      .clamp(0.0, maxDrag);
                });
              },
              onHorizontalDragEnd: (details) {
                setState(() {
                  _isDragging = false;
                });

                if (_dragPosition > maxDrag / 2) {
                  if (!widget.isOnline) {
                    widget.onToggle();
                  }
                } else {
                  if (widget.isOnline) {
                    widget.onToggle();
                  }
                }
              },
              onTap: widget.onToggle,
              child: Container(
                width: thumbWidth,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.isOnline
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.isOnline ? Icons.verified : Icons.do_not_disturb_on,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isOnline ? 'Online' : 'Offline',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
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
