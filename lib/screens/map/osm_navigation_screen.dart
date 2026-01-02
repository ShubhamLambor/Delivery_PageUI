import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'dart:async';

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

  // Live tracking variables
  StreamSubscription<Position>? _positionStreamSubscription;
  bool isTrackingEnabled = true;
  double currentSpeed = 0.0; // in km/h
  Timer? _routeUpdateTimer;
  GeoPoint? lastRouteUpdateLocation;

  // Modern color palette
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color accentOrange = Color(0xFFFF6B35);

  @override
  void initState() {
    super.initState();

    // Enable all orientations for map screen
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

    setState(() {
      isMapReady = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    await _drawRoute();

    // Start live tracking
    _startLiveTracking();
  }

  // Start live location tracking
  void _startLiveTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      if (!mounted || !isTrackingEnabled) return;

      // Calculate speed in km/h
      currentSpeed = (position.speed * 3.6);

      // Update current location
      final newLocation = GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (mounted) {
        setState(() {
          currentLocation = newLocation;
        });
      }

      // Update marker position on map
      await _updateCurrentLocationMarker(newLocation);

      // Update route every 50 meters or 30 seconds
      if (_shouldUpdateRoute(newLocation)) {
        await _updateRoute(newLocation);
        lastRouteUpdateLocation = newLocation;
      }

      debugPrint('Live tracking: ${position.latitude}, ${position.longitude}, Speed: ${currentSpeed.toStringAsFixed(1)} km/h');
    });
  }

  // Check if route should be updated
  bool _shouldUpdateRoute(GeoPoint newLocation) {
    if (lastRouteUpdateLocation == null) return true;

    // Calculate distance from last update
    final distance = Geolocator.distanceBetween(
      lastRouteUpdateLocation!.latitude,
      lastRouteUpdateLocation!.longitude,
      newLocation.latitude,
      newLocation.longitude,
    );

    // Update if moved more than 50 meters
    return distance > 50;
  }

  // Update current location marker
  Future<void> _updateCurrentLocationMarker(GeoPoint newLocation) async {
    if (!isMapReady || mapController == null) return;

    try {
      // Update map center smoothly
      if (isTrackingEnabled) {
        await mapController!.changeLocation(newLocation);
      }
    } catch (e) {
      debugPrint('Error updating marker: $e');
    }
  }

  // Update route dynamically
  Future<void> _updateRoute(GeoPoint newLocation) async {
    if (!isMapReady || mapController == null || !mounted) return;

    try {
      final destination = GeoPoint(
        latitude: widget.destinationLat,
        longitude: widget.destinationLng,
      );

      // Clear old road
      await mapController!.clearAllRoads();

      // Redraw route from new location
      roadInfo = await mapController!.drawRoad(
        newLocation,
        destination,
        roadType: RoadType.car,
        roadOption: RoadOption(
          roadWidth: 8,
          roadColor: primaryGreen,
          roadBorderWidth: 1.5,
          roadBorderColor: primaryGreen.withOpacity(0.3),
          zoomInto: false, // Don't zoom on update
        ),
      );

      if (mounted) {
        setState(() {});
      }

      debugPrint('Route updated: ${roadInfo?.distance} km, ${roadInfo?.duration}s');
    } catch (e) {
      debugPrint('Error updating route: $e');
    }
  }

  Future<void> _drawRoute() async {
    if (!isMapReady || mapController == null || !mounted) return;

    setState(() {
      isLoadingRoute = true;
    });

    try {
      final destination = GeoPoint(
        latitude: widget.destinationLat,
        longitude: widget.destinationLng,
      );

      // Add modern current location marker
      await mapController!.addMarker(
        currentLocation!,
        markerIcon: MarkerIcon(
          iconWidget: _buildModernMarker(
            icon: Icons.my_location_rounded,
            color: googleBlue,
            size: 56,
          ),
        ),
      );

      // Add modern destination marker
      await mapController!.addMarker(
        destination,
        markerIcon: MarkerIcon(
          iconWidget: _buildModernMarker(
            icon: Icons.location_on,
            color: accentOrange,
            size: 64,
          ),
        ),
      );

      // Draw route
      roadInfo = await mapController!.drawRoad(
        currentLocation!,
        destination,
        roadType: RoadType.car,
        roadOption: RoadOption(
          roadWidth: 8,
          roadColor: primaryGreen,
          roadBorderWidth: 1.5,
          roadBorderColor: primaryGreen.withOpacity(0.3),
          zoomInto: true,
        ),
      );

      lastRouteUpdateLocation = currentLocation;
      debugPrint('Route: ${roadInfo?.distance} km, ${roadInfo?.duration}s');
    } catch (e) {
      debugPrint('Error drawing route: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to calculate route');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingRoute = false;
        });
      }
    }
  }

  Widget _buildModernMarker({
    required IconData icon,
    required Color color,
    required double size,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size + 4,
          height: size + 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        Container(
          width: size * 0.7,
          height: size * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        Icon(
          icon,
          color: color,
          size: size,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ],
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showMyLocation() async {
    if (currentLocation != null && isMapReady && mapController != null) {
      setState(() {
        isTrackingEnabled = true;
      });

      await mapController!.goToLocation(currentLocation!);
      await Future.delayed(const Duration(milliseconds: 100));
      await mapController!.setZoom(zoomLevel: 16);
    }
  }

  Future<void> _showDestination() async {
    if (!isMapReady || mapController == null) return;

    setState(() {
      isTrackingEnabled = false;
    });

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

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _pulseController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 3),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryGreen, lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                border: Border.all(
                  color: Colors.black.withOpacity(0.1),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: AppBar(
                title: Text(
                  widget.destinationName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 18,
                    letterSpacing: 0.3,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white, size: 24),
                actions: [
                  if (roadInfo != null) _buildInfoCard(),
                ],
              ),
            ),
            Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
      body: isInitializing || mapController == null
          ? _buildLoadingScreen()
          : Stack(
        children: [
          OSMFlutter(
            controller: mapController!,
            onMapIsReady: (isReady) {
              if (isReady) _onMapReady();
            },
            osmOption: OSMOption(
              userTrackingOption: const UserTrackingOption(
                enableTracking: true,
                unFollowUser: false,
              ),
              zoomOption: const ZoomOption(
                initZoom: 15,
                minZoomLevel: 8,
                maxZoomLevel: 19,
                stepZoom: 1.0,
              ),
              staticPoints: const [],
              showDefaultInfoWindow: false,
            ),
          ),
          if (isLoadingRoute) _buildRouteLoadingOverlay(),
          _buildLiveTrackingIndicator(),
        ],
      ),
      floatingActionButton: isInitializing || mapController == null
          ? null
          : _buildFloatingButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildLiveTrackingIndicator() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isTrackingEnabled ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    boxShadow: isTrackingEnabled
                        ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.6 * _pulseController.value),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                        : null,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              isTrackingEnabled ? 'Live Tracking' : 'Paused',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isTrackingEnabled ? Colors.green.shade700 : Colors.grey.shade700,
              ),
            ),
            if (currentSpeed > 0 && isTrackingEnabled) ...[
              const SizedBox(width: 8),
              Text(
                '${currentSpeed.toStringAsFixed(0)} km/h',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.straighten, size: 12, color: primaryGreen),
          const SizedBox(width: 4),
          Text(
            '${(roadInfo!.distance ?? 0).toStringAsFixed(1)} km',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 1,
            height: 16,
            color: Colors.grey[300],
          ),
          Icon(Icons.schedule, size: 12, color: accentOrange),
          const SizedBox(width: 4),
          Text(
            '${((roadInfo!.duration ?? 0) / 60).toStringAsFixed(0)} min',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.grey[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withOpacity(0.3 * _pulseController.value),
                        blurRadius: 30,
                        spreadRadius: 10 * _pulseController.value,
                      ),
                    ],
                  ),
                  child: const CircularProgressIndicator(
                    color: primaryGreen,
                    strokeWidth: 3,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading map...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteLoadingOverlay() {
    return Container(
      color: Colors.black38,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: primaryGreen,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Calculating route...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Please wait',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          shadowColor: Colors.black.withOpacity(0.2),
          child: InkWell(
            onTap: _showMyLocation,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.my_location_rounded,
                color: googleBlue,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(28),
          shadowColor: primaryGreen.withOpacity(0.4),
          child: InkWell(
            onTap: _showDestination,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryGreen, lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Destination',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
