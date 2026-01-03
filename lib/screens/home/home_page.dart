// lib/screens/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'home_controller.dart';
import '../../screens/home/widgets/current_delivery_card.dart';
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
  // ... (Permission code remains same) ...
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermission();
    });
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) { if (mounted) _showLocationServiceDialog(); return; }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) { if (mounted) _showPermissionDeniedDialog(); return; }
    }
    if (permission == LocationPermission.deniedForever) { if (mounted) _showPermissionPermanentlyDeniedDialog(); return; }
  }

  void _showLocationServiceDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Location Services Disabled'), content: const Text('Please enable location services.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
  }

  void _showPermissionDeniedDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Permission Required'), content: const Text('App needs location access.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () {Navigator.pop(context); _requestLocationPermission();}, child: const Text('Retry'))]));
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Permission Denied'), content: const Text('Enable location in settings.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () {Geolocator.openAppSettings(); Navigator.pop(context);}, child: const Text('Settings'))]));
  }

  Future<void> _navigateToMess() async {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const OSMNavigationScreen(destinationLat: 19.0760, destinationLng: 72.8777, destinationName: 'Shree Kitchen')));
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    final auth = context.watch<AuthController>();

    final DeliveryModel? current = home.currentDelivery;
    final List<DeliveryModel> upcoming = home.upcomingDeliveries;

    final completed = home.completedCount;
    final pending = home.pendingCount;
    final cancelled = home.cancelledCount;

    final isOnline = home.isOnline;
    final userName = auth.user?.name ?? 'Delivery Partner';
    final now = DateTime.now();
    final dateStr = DateFormat('EEE, d MMM').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. Header Area ---
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              height: 240,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOnline
                      ? [const Color(0xFF2E7D32), const Color(0xFF4CAF50)]
                      : [const Color(0xFFC62828), const Color(0xFFEF5350)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello, $userName', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: isOnline ? Colors.green : Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SwipeToggleButton(isOnline: isOnline, onToggle: home.toggleOnline),
                ],
              ),
            ),

            // --- 2. Floating Stats Grid (Shifted UP over header) ---
            Transform.translate(
              offset: const Offset(0, -60), // Pulls grid UP
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard('Today\'s Earnings', '₹320', Icons.currency_rupee, Colors.orange),
                    _buildStatCard('Completed', '$completed', Icons.check_circle, Colors.green),
                    _buildStatCard('Pending', '$pending', Icons.access_time, Colors.blue),
                    _buildStatCard('Cancelled', '$cancelled', Icons.cancel, Colors.red),
                  ],
                ),
              ),
            ),

            // --- 3. Main Content Area (Shifted UP to close gap) ---
            // We shift this UP by a larger amount (-80) to cover the empty space left by the grid moving up.
            Transform.translate(
              offset: const Offset(0, -80),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (current != null) ...[
                      const Text('Active Delivery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      CurrentDeliveryCard(delivery: current),
                      const SizedBox(height: 24),
                    ],

                    const Text('Next Pickup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildPickupCard(),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Upcoming Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text('${upcoming.length}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (upcoming.isEmpty)
                      Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("No upcoming orders", style: TextStyle(color: Colors.grey[500]))))
                    else
                      Column(children: upcoming.map((d) => UpcomingTile(delivery: d)).toList()),

                    // Add extra bottom padding because Transform might cut off the bottom
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers (Same) ---
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
              const Spacer(),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPickupCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.store, color: Colors.orange, size: 20)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shree Kitchen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Pickup Point', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)), child: const Text('25 Tiffins', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              const Text('10:15 - 10:45 AM', style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToMess,
              icon: const Icon(Icons.navigation, size: 18),
              label: const Text('Navigate to Mess'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- DYNAMIC SLIDE-TO-UNLOCK BUTTON (Same) ---
class SwipeToggleButton extends StatefulWidget {
  final bool isOnline;
  final VoidCallback onToggle;
  const SwipeToggleButton({super.key, required this.isOnline, required this.onToggle});
  @override
  State<SwipeToggleButton> createState() => _SwipeToggleButtonState();
}

class _SwipeToggleButtonState extends State<SwipeToggleButton> {
  double _dragPosition = 0.0;
  bool _isDragging = false;
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width - 40;
    const height = 54.0;
    final thumbWidth = screenWidth / 2;
    final maxDrag = screenWidth - thumbWidth;
    final targetPosition = widget.isOnline ? maxDrag : 0.0;
    final currentPosition = _isDragging ? _dragPosition : targetPosition;
    final double dragPercentage = (currentPosition / maxDrag).clamp(0.0, 1.0);
    final Color backgroundColor = Color.lerp(Colors.red.shade400, Colors.green.shade600, dragPercentage)!;

    return Container(
      height: height,
      width: screenWidth,
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: backgroundColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))], border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5)),
      child: Stack(children: [Row(children: [Expanded(child: Center(child: AnimatedOpacity(opacity: (!widget.isOnline && !_isDragging) ? 1.0 : 0.5, duration: const Duration(milliseconds: 200), child: const Text('Offline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))))), Expanded(child: Center(child: AnimatedOpacity(opacity: (widget.isOnline && !_isDragging) ? 1.0 : 0.5, duration: const Duration(milliseconds: 200), child: const Text('Online', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)))))]), AnimatedPositioned(duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300), curve: Curves.easeOutBack, left: currentPosition, top: 2, bottom: 2, child: GestureDetector(onHorizontalDragStart: (_) => setState(() { _isDragging = true; _dragPosition = targetPosition; }), onHorizontalDragUpdate: (d) => setState(() => _dragPosition = (_dragPosition + d.delta.dx).clamp(0.0, maxDrag)), onHorizontalDragEnd: (d) { setState(() => _isDragging = false); if ((_dragPosition > maxDrag / 2) != widget.isOnline) widget.onToggle(); }, onTap: widget.onToggle, child: Container(width: thumbWidth - 4, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))]), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(widget.isOnline ? Icons.verified_user : Icons.power_settings_new, color: backgroundColor, size: 20), const SizedBox(width: 8), Text(widget.isOnline ? 'Online' : 'Offline', style: TextStyle(color: backgroundColor, fontWeight: FontWeight.bold, fontSize: 14))]))))]),
    );
  }
}
