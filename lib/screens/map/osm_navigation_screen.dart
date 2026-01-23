import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';

class OSMNavigationScreen extends StatefulWidget {
  final double destinationLat;
  final double destinationLng;
  final String destinationName;

  const OSMNavigationScreen({
    super.key,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationName,
  });

  @override
  State<OSMNavigationScreen> createState() => _OSMNavigationScreenState();
}

class _OSMNavigationScreenState extends State<OSMNavigationScreen>
    with SingleTickerProviderStateMixin {
  // --- Controllers ---
  late MapController mapController;
  late AnimationController _pulseController;

  // --- State Variables ---
  GeoPoint? _currentLocation;
  RoadInfo? _roadInfo;
  bool _isMapReady = false;
  bool _isTracking = true; // Auto-follow user
  bool _isLoadingRoute = false;
  double _currentSpeed = 0.0;
  double _currentHeading = 0.0;
  double? _remainingDistanceKm;

  // ✅ ADDED: Grace period to prevent instant arrival on load
  bool _canTriggerArrival = false;

  // --- Streams ---
  StreamSubscription<Position>? _positionStream;

  // --- Constants ---
  static const Color primaryColor = Color(0xFF2563EB); // Royal Blue
  static const Color accentColor = Color(0xFF10B981); // Emerald Green
  static const Color darkText = Color(0xFF1F2937);

  @override
  void initState() {
    super.initState();
    // Keep screen on for navigation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Pulse animation for rider marker
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Initialize Map Controller
    mapController = MapController(
      initMapWithUserPosition: const UserTrackingOption(
        enableTracking: true,
        unFollowUser: false,
      ),
    );

    // ✅ ADDED: Start Grace Period Timer (10 seconds)
    // We won't check for "Arrival" until 10 seconds have passed to let GPS stabilize
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _canTriggerArrival = true);
        debugPrint("⏰ Grace period over. Arrival detection enabled.");
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    mapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // --- Logic ---

  Future<void> _onMapReady(bool isReady) async {
    if (!isReady) return;

    if (mounted) {
      setState(() => _isMapReady = true);
    }

    // 1. Get Initial Location
    try {
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (!mounted) return;

      _currentLocation =
          GeoPoint(latitude: pos.latitude, longitude: pos.longitude);

      // 2. Add Destination Marker
      await mapController.addMarker(
        GeoPoint(
            latitude: widget.destinationLat, longitude: widget.destinationLng),
        markerIcon: const MarkerIcon(
          icon: Icon(Icons.location_on, color: Colors.red, size: 60),
        ),
      );

      // 3. Draw Initial Route
      await _calculateRoute();

      // 4. Start Live Tracking
      _startTracking();
    } catch (e) {
      debugPrint("❌ Map Init Error: $e");
    }
  }

  Future<void> _calculateRoute() async {
    if (_currentLocation == null) return;
    if (mounted) setState(() => _isLoadingRoute = true);

    try {
      _roadInfo = await mapController.drawRoad(
        _currentLocation!,
        GeoPoint(
            latitude: widget.destinationLat, longitude: widget.destinationLng),
        roadType: RoadType.car,
        roadOption: const RoadOption(
          roadWidth: 10,
          roadColor: primaryColor,
          roadBorderWidth: 3,
          roadBorderColor: Colors.white,
          zoomInto: true,
        ),
      );

      if (_roadInfo?.distance != null && mounted) {
        setState(() {
          _remainingDistanceKm = _roadInfo!.distance;
        });
      }
    } catch (e) {
      debugPrint("❌ Route Error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  void _startTracking() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: settings)
        .listen((Position pos) {
      if (!mounted) return;

      final newGeo = GeoPoint(latitude: pos.latitude, longitude: pos.longitude);

      setState(() {
        _currentLocation = newGeo;
        _currentSpeed = (pos.speed * 3.6);
        _currentHeading = pos.heading;

        // Calculate distance
        final distMeters = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          widget.destinationLat,
          widget.destinationLng,
        );
        _remainingDistanceKm = distMeters / 1000;

        // Debug Log
        // debugPrint("📍 Dist: ${distMeters.toStringAsFixed(1)}m | Can Trigger: $_canTriggerArrival");
      });

      // ✅ UPDATED: Arrival check (< 50 meters)
      // Only trigger if grace period is over AND distance is valid
      if (_canTriggerArrival &&
          _remainingDistanceKm != null &&
          _remainingDistanceKm! < 0.05) { // 0.05 km = 50 meters
        _showArrivalDialog();
      }

      if (_isTracking && _isMapReady) {
        mapController.moveTo(newGeo, animate: true);
      }
    });
  }

  void _recenter() {
    if (mounted) setState(() => _isTracking = true);
    if (_currentLocation != null) {
      mapController.moveTo(_currentLocation!, animate: true);
      mapController.setZoom(zoomLevel: 18);
    }
  }

  void _showArrivalDialog() {
    // Prevent multiple dialogs by pausing stream
    _positionStream?.pause();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: accentColor, size: 60),
            SizedBox(height: 10),
            Text("You have arrived!", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "You are at ${widget.destinationName}",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Go back to Home Screen
              },
              child: const Text("Complete Delivery",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          OSMFlutter(
            controller: mapController,
            onMapIsReady: _onMapReady,
            osmOption: OSMOption(
              userTrackingOption: const UserTrackingOption(
                enableTracking: true,
                unFollowUser: false,
              ),
              zoomOption: const ZoomOption(
                initZoom: 18,
                minZoomLevel: 4,
                maxZoomLevel: 19,
                stepZoom: 1.0,
              ),
              userLocationMarker: UserLocationMaker(
                personMarker: const MarkerIcon(
                  icon: Icon(Icons.navigation, color: primaryColor, size: 60),
                ),
                directionArrowMarker: const MarkerIcon(
                  icon: Icon(Icons.navigation, color: primaryColor, size: 60),
                ),
              ),
              roadConfiguration: const RoadOption(
                roadColor: Colors.blueGrey,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: _buildTopCard(),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomCard(),
          ),
          Positioned(
            bottom: 220,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: "recenter",
                  backgroundColor: Colors.white,
                  child: Icon(
                    _isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
                    color: _isTracking ? primaryColor : Colors.grey,
                  ),
                  onPressed: _recenter,
                ),
                const SizedBox(height: 12),
                if (_currentSpeed > 2)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentSpeed.toStringAsFixed(0),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: darkText,
                              height: 1.0,
                            ),
                          ),
                          const Text(
                            "km/h",
                            style: TextStyle(fontSize: 10, color: Colors.grey, height: 1.0),
                          )
                        ],
                      ),
                    ),
                  )
              ],
            ),
          ),
          if (_isLoadingRoute || !_isMapReady)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    SizedBox(height: 16),
                    Text("Loading Map...", style: TextStyle(color: darkText, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Navigating to",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  widget.destinationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard() {
    final distStr = _remainingDistanceKm != null
        ? "${_remainingDistanceKm!.toStringAsFixed(1)} km"
        : "--";

    final minutes = _remainingDistanceKm != null
        ? (_remainingDistanceKm! / 30 * 60).round()
        : 0;
    final timeStr = minutes >= 60
        ? "${(minutes / 60).toStringAsFixed(1)} hr"
        : "$minutes min";

    final now = DateTime.now();
    final arrivalTime = now.add(Duration(minutes: minutes));
    final arrivalStr = "${arrivalTime.hour}:${arrivalTime.minute.toString().padLeft(2, '0')}";

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(Icons.access_time_filled, timeStr, "Est. Time"),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              _buildStatItem(Icons.near_me, distStr, "Distance"),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              _buildStatItem(Icons.schedule, arrivalStr, "Arrival"),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("Arrived at Location",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: _showArrivalDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: primaryColor),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}