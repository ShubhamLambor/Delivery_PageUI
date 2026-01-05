// lib/screens/map/osm_navigation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;

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
  MapController? mapController;
  GeoPoint? currentLocation;
  RoadInfo? roadInfo;
  bool isLoadingRoute = false;
  bool isMapReady = false;
  bool isInitializing = true;
  late AnimationController _pulseController;

  StreamSubscription<Position>? _positionStreamSubscription;
  bool isTrackingEnabled = true;
  double currentSpeed = 0.0;
  double currentHeading = 0.0;
  Timer? _routeUpdateTimer;
  GeoPoint? lastRouteUpdateLocation;

  // Clean modern color palette
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color darkGray = Color(0xFF1F2937);
  static const Color lightGray = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentLocation = GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      currentHeading = position.heading;
    } catch (e) {
      debugPrint('Error getting location: $e');
      currentLocation = GeoPoint(
        latitude: widget.destinationLat,
        longitude: widget.destinationLng,
      );
    }

    mapController = MapController(
      initPosition: currentLocation!,
    );

    if (mounted) {
      setState(() {
        isInitializing = false;
      });
    }
  }

  Future<void> _onMapReady() async {
    if (!mounted) return;
    setState(() => isMapReady = true);
    await Future.delayed(const Duration(milliseconds: 500));
    await _drawRoute();
    _startLiveTracking();
  }

  void _startLiveTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      if (!mounted || !isTrackingEnabled) return;

      currentSpeed = (position.speed * 3.6);
      currentHeading = position.heading;

      final newLocation = GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (mounted) setState(() => currentLocation = newLocation);

      await _updateCurrentLocationMarker(newLocation);

      if (_shouldUpdateRoute(newLocation)) {
        await _updateRoute(newLocation);
        lastRouteUpdateLocation = newLocation;
      }
    });
  }

  bool _shouldUpdateRoute(GeoPoint newLocation) {
    if (lastRouteUpdateLocation == null) return true;
    final distance = Geolocator.distanceBetween(
      lastRouteUpdateLocation!.latitude,
      lastRouteUpdateLocation!.longitude,
      newLocation.latitude,
      newLocation.longitude,
    );
    return distance > 50;
  }

  Future<void> _updateCurrentLocationMarker(GeoPoint newLocation) async {
    if (!isMapReady || mapController == null) return;
    try {
      if (isTrackingEnabled) {
        await mapController!.changeLocation(newLocation);
      }
    } catch (e) {
      debugPrint('Error updating marker: $e');
    }
  }

  Future<void> _updateRoute(GeoPoint newLocation) async {
    if (!isMapReady || mapController == null || !mounted) return;

    try {
      final destination = GeoPoint(
        latitude: widget.destinationLat,
        longitude: widget.destinationLng,
      );

      await mapController!.clearAllRoads();

      roadInfo = await mapController!.drawRoad(
        newLocation,
        destination,
        roadType: RoadType.car,
        roadOption: RoadOption(
          roadWidth: 10,
          roadColor: accentGreen,
          roadBorderWidth: 2,
          roadBorderColor: Colors.white,
          zoomInto: false,
        ),
      );

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error updating route: $e');
    }
  }

  Future<void> _drawRoute() async {
    if (!isMapReady || mapController == null || !mounted) return;

    setState(() => isLoadingRoute = true);

    try {
      final destination = GeoPoint(
        latitude: widget.destinationLat,
        longitude: widget.destinationLng,
      );

      // Rider marker (bike icon style)
      await mapController!.addMarker(
        currentLocation!,
        markerIcon: MarkerIcon(
          iconWidget: _buildRiderMarker(
            size: 80,
            rotation: currentHeading,
          ),
        ),
      );

      // Destination marker (minimal pin)
      await mapController!.addMarker(
        destination,
        markerIcon: MarkerIcon(
          iconWidget: _buildDestinationMarker(size: 60),
        ),
      );

      // Draw route with white border
      roadInfo = await mapController!.drawRoad(
        currentLocation!,
        destination,
        roadType: RoadType.car,
        roadOption: RoadOption(
          roadWidth: 10,
          roadColor: accentGreen,
          roadBorderWidth: 2,
          roadBorderColor: Colors.white,
          zoomInto: true,
        ),
      );

      lastRouteUpdateLocation = currentLocation;
    } catch (e) {
      debugPrint('Error drawing route: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to calculate route'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoadingRoute = false);
    }
  }

  // 🚴 Rider Marker (Delivery Partner Location)
  Widget _buildRiderMarker({required double size, double rotation = 0}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing outer ring
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: size + (12 * _pulseController.value),
              height: size + (12 * _pulseController.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryBlue.withOpacity(0.15 * (1 - _pulseController.value)),
              ),
            );
          },
        ),
        // Main circle
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: primaryBlue, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        // Navigation arrow
        Transform.rotate(
          angle: rotation * (math.pi / 180),
          child: Icon(
            Icons.navigation,
            color: primaryBlue,
            size: size * 0.6,
          ),
        ),
      ],
    );
  }

  // 📍 Destination Marker (Clean Pin)
  Widget _buildDestinationMarker({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.location_on,
        color: accentGreen,
        size: size * 0.85,
      ),
    );
  }

  Future<void> _showMyLocation() async {
    if (currentLocation != null && isMapReady && mapController != null) {
      setState(() => isTrackingEnabled = true);
      await mapController!.goToLocation(currentLocation!);
      await Future.delayed(const Duration(milliseconds: 100));
      await mapController!.setZoom(zoomLevel: 17);
    }
  }

  Future<void> _showDestination() async {
    if (!isMapReady || mapController == null) return;
    setState(() => isTrackingEnabled = false);
    final destination = GeoPoint(
      latitude: widget.destinationLat,
      longitude: widget.destinationLng,
    );
    await mapController!.goToLocation(destination);
    await Future.delayed(const Duration(milliseconds: 100));
    await mapController!.setZoom(zoomLevel: 17);
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _routeUpdateTimer?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _pulseController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      extendBodyBehindAppBar: true,
      body: isInitializing || mapController == null
          ? _buildLoadingScreen()
          : Stack(
        children: [
          // Full-screen map
          OSMFlutter(
            controller: mapController!,
            onMapIsReady: (isReady) {
              if (isReady) _onMapReady();
            },
            osmOption: OSMOption(
              userTrackingOption: const UserTrackingOption(
                enableTracking: false,
                unFollowUser: true,
              ),
              zoomOption: const ZoomOption(
                initZoom: 17,
                minZoomLevel: 10,
                maxZoomLevel: 19,
              ),
              staticPoints: const [],
              showDefaultInfoWindow: false,
            ),
          ),
          // Top floating header
          _buildTopHeader(),
          // Right-side floating controls
          _buildFloatingControls(),
          // Bottom CTA button
          _buildBottomCTA(),
          // Loading overlay
          if (isLoadingRoute) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // 📱 Top Floating Header (Compact Info Card)
  Widget _buildTopHeader() {
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Back button
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            // Destination info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.destinationName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: darkGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (roadInfo != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.route, size: 14, color: lightGray),
                        const SizedBox(width: 4),
                        Text(
                          '${(roadInfo!.distance ?? 0).toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: lightGray,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time, size: 14, color: lightGray),
                        const SizedBox(width: 4),
                        Text(
                          '${((roadInfo!.duration ?? 0) / 60).toStringAsFixed(0)} min',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: lightGray,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Status pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: accentGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isTrackingEnabled ? 'On the way' : 'Paused',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accentGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎛️ Right-Side Floating Controls
  Widget _buildFloatingControls() {
    return Positioned(
      right: 16,
      top: 150,
      child: Column(
        children: [
          // Re-center button
          _buildCircularButton(
            icon: Icons.my_location_rounded,
            onTap: _showMyLocation,
          ),
          const SizedBox(height: 12),
          // Speed indicator
          if (currentSpeed > 1)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    currentSpeed.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: primaryBlue,
                    ),
                  ),
                  Text(
                    'km/h',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: lightGray,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCircularButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: darkGray, size: 24),
        ),
      ),
    );
  }

  // 🎯 Bottom CTA Button
  Widget _buildBottomCTA() {
    return Positioned(
      bottom: 30,
      left: 16,
      right: 16,
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          onTap: _showDestination,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentGreen, accentGreen.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: accentGreen.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'View Destination',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Loading states
  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: primaryBlue,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading navigation...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryBlue, strokeWidth: 3),
              SizedBox(height: 16),
              Text(
                'Calculating route...',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
