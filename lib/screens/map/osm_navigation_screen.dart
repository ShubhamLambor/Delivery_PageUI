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

enum MapLayer { standard, terrain, satellite }

class _OSMNavigationScreenState extends State<OSMNavigationScreen>
    with SingleTickerProviderStateMixin {
  late MapController mapController;

  // State Variables
  GeoPoint? _currentLocation;
  RoadInfo? _roadInfo;
  bool _isMapReady = false;
  bool _isTracking = true;
  bool _isLoadingRoute = false;
  bool _layersExpanded = false; // For the FAB menu

  // Navigation Stats
  double _currentSpeed = 0.0;
  double _currentHeading = 0.0;
  double? _remainingDistanceKm;
  double? _timeToArrivalSeconds; // derived from RoadInfo

  // Arrival Logic
  bool _canTriggerArrival = false;
  bool _hasShownArrivalDialog = false;
  MapLayer _currentLayer = MapLayer.standard;

  StreamSubscription<Position>? _positionStream;

  // Design Constants
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color accentColor = Color(0xFF10B981);
  static const Color darkText = Color(0xFF1F2937);
  static const Color surfaceColor = Colors.white;

  // Map Tile Configurations
  static final Map<MapLayer, CustomTile> _layers = {
    MapLayer.standard: CustomTile(
      urlsServers: [TileURLs(url: "https://tile.openstreetmap.org/{z}/{x}/{y}.png")],
      sourceName: "OpenStreetMap",
      tileExtension: ".png",
    ),
    MapLayer.terrain: CustomTile(
      minZoomLevel: 2,
      maxZoomLevel: 19,
      urlsServers: [TileURLs(url: "https://a.tile.opentopomap.org/{z}/{x}/{y}.png")],
      sourceName: "OpenTopoMap",
      tileExtension: ".png",
    ),
    MapLayer.satellite: CustomTile(
      minZoomLevel: 2,
      maxZoomLevel: 19,
      urlsServers: [TileURLs(url: "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}")],
      sourceName: "Esri World Imagery",
      tileExtension: ".png",
    ),
  };

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    mapController = MapController(
      initMapWithUserPosition: const UserTrackingOption(
        enableTracking: true,
        unFollowUser: false,
      ),
    );

    // Grace period to prevent instant arrival triggering if GPS drifts at start
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _canTriggerArrival = true);
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    mapController.dispose();
    super.dispose();
  }

  Future<void> _onMapReady(bool isReady) async {
    if (!isReady) return;

    if (mounted) setState(() => _isMapReady = true);

    try {
      // 1. Permission Check
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if(mounted) _showErrorSnackBar("Location permission is required for navigation.");
          return;
        }
      }

      // 2. Initial Position
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      if (!mounted) return;

      setState(() {
        _currentLocation = GeoPoint(latitude: pos.latitude, longitude: pos.longitude);
      });

      // 3. Add Destination Marker
      await mapController.addMarker(
        GeoPoint(latitude: widget.destinationLat, longitude: widget.destinationLng),
        markerIcon: const MarkerIcon(
          icon: Icon(
            Icons.location_on,
            color: Colors.redAccent,
            size: 64, // Slightly smaller for better precision look
          ),
        ),
      );

      // 4. Start Route & Tracking
      await _calculateRoute();
      _startTracking();

      // 5. Initial Zoom
      await mapController.setZoom(zoomLevel: 17);

    } catch (e) {
      debugPrint("❌ Map Init Error: $e");
    }
  }

  Future<void> _calculateRoute() async {
    if (_currentLocation == null) return;
    if (mounted) setState(() => _isLoadingRoute = true);

    // Remove old road if exists (to avoid duplicates during reroute)
    try {
      await mapController.removeLastRoad();
    } catch (_) {}

    try {
      _roadInfo = await mapController.drawRoad(
        _currentLocation!,
        GeoPoint(latitude: widget.destinationLat, longitude: widget.destinationLng),
        roadType: RoadType.car,
        roadOption: const RoadOption(
          roadWidth: 12, // Thicker road for visibility
          roadColor: primaryColor,
          roadBorderWidth: 4,
          roadBorderColor: Colors.white,
          zoomInto: true,
        ),
      );

      if (_roadInfo != null && mounted) {
        setState(() {
          _remainingDistanceKm = _roadInfo!.distance;
          _timeToArrivalSeconds = _roadInfo!.duration; // Use actual route duration
        });
      }
    } catch (e) {
      debugPrint("❌ Route Error: $e");
      if(mounted) _showErrorSnackBar("Could not calculate route.");
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
        _currentSpeed = pos.speed * 3.6; // Convert m/s to km/h
        _currentHeading = pos.heading;

        // Simple straight line distance for UI updates between route recalcs
        final distMeters = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          widget.destinationLat,
          widget.destinationLng,
        );
        _remainingDistanceKm = distMeters / 1000;

        // Adjust time linearly based on speed if we have a previous estimate
        if (_timeToArrivalSeconds != null && _currentSpeed > 5) {
          // Basic decay of time
          _timeToArrivalSeconds = (_remainingDistanceKm! / (_currentSpeed / 3600));
        }
      });

      // Arrival Detection
      if (!_hasShownArrivalDialog &&
          _canTriggerArrival &&
          _remainingDistanceKm != null &&
          _remainingDistanceKm! < 0.05) { // 50 meters
        _showArrivalDialog();
      }

      // Map Tracking Camera Update
      if (_isTracking && _isMapReady) {
        mapController.moveTo(newGeo, animate: true);
        // Optional: Rotate map to heading if speed is sufficient
        if (_currentSpeed > 10) {
          // mapController.rotateMapCamera(_currentHeading); // Uncomment if plugin supports rotation seamlessly
        }
      }
    });
  }

  void _recenter() {
    setState(() => _isTracking = true);
    if (_currentLocation != null) {
      mapController.moveTo(_currentLocation!, animate: true);
      mapController.setZoom(zoomLevel: 18);
    }
  }

  Future<void> _switchLayer(MapLayer layer) async {
    if (_currentLayer == layer || !_isMapReady) return;
    try {
      await mapController.changeTileLayer(tileLayer: _layers[layer]!);
      setState(() {
        _currentLayer = layer;
        _layersExpanded = false; // Close menu after selection
      });
    } catch (e) {
      debugPrint("❌ Layer switch error: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showArrivalDialog() {
    _hasShownArrivalDialog = true;
    _positionStream?.pause();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: accentColor, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              "You have arrived!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText),
            ),
            const SizedBox(height: 8),
            Text(
              "Destination: ${widget.destinationName}",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Exit screen
                },
                child: const Text("Complete Trip", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Layer
          OSMFlutter(
            controller: mapController,
            onMapIsReady: _onMapReady,
            osmOption: OSMOption(
              userTrackingOption: const UserTrackingOption(
                enableTracking: true,
                unFollowUser: false,
              ),
              zoomOption: const ZoomOption(
                initZoom: 16,
                minZoomLevel: 4,
                maxZoomLevel: 19,
                stepZoom: 1.0,
              ),
              userLocationMarker: UserLocationMaker(
                personMarker: const MarkerIcon(
                  icon: Icon(
                    Icons.navigation, // Use navigation arrow for clearer heading
                    color: primaryColor,
                    size: 48,
                  ),
                ),
                directionArrowMarker: const MarkerIcon(
                  icon: Icon(
                    Icons.navigation,
                    color: primaryColor,
                    size: 48,
                  ),
                ),
              ),
              roadConfiguration: const RoadOption(
                roadColor: primaryColor,
              ),
            ),
          ),

          // 2. Top Navigation Bar (Floating Pill)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: _buildTopBar(),
          ),

          // 3. Right Side Controls (Layers & Reroute)
          Positioned(
            top: 120,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildLayerControl(),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: "reroute",
                  backgroundColor: surfaceColor,
                  foregroundColor: primaryColor,
                  tooltip: "Recalculate Route",
                  onPressed: _calculateRoute,
                  child: _isLoadingRoute
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.alt_route_rounded),
                ),
              ],
            ),
          ),

          // 4. Bottom Controls (Recenter & Speed)
          Positioned(
            bottom: 240, // Just above the bottom sheet
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: "recenter",
                  backgroundColor: surfaceColor,
                  child: Icon(
                    _isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
                    color: _isTracking ? primaryColor : Colors.grey,
                  ),
                  onPressed: _recenter,
                ),
                const SizedBox(height: 16),
                if (_currentSpeed > 2) _buildSpeedBadge(),
              ],
            ),
          ),

          // 5. Bottom Info Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomCard(),
          ),
        ],
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Navigating to",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.destinationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12)
            ),
            child: const Icon(Icons.location_on, size: 16, color: Colors.red),
          )
        ],
      ),
    );
  }

  Widget _buildLayerControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_layersExpanded) ...[
          _layerOption(MapLayer.satellite, Icons.satellite_alt),
          const SizedBox(height: 8),
          _layerOption(MapLayer.terrain, Icons.terrain),
          const SizedBox(height: 8),
          _layerOption(MapLayer.standard, Icons.map),
          const SizedBox(height: 8),
        ],
        FloatingActionButton.small(
          heroTag: "layers_toggle",
          backgroundColor: surfaceColor,
          foregroundColor: darkText,
          onPressed: () => setState(() => _layersExpanded = !_layersExpanded),
          child: Icon(_layersExpanded ? Icons.close : Icons.layers),
        ),
      ],
    );
  }

  Widget _layerOption(MapLayer layer, IconData icon) {
    final isSelected = _currentLayer == layer;
    return GestureDetector(
      onTap: () => _switchLayer(layer),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : surfaceColor,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildSpeedBadge() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: surfaceColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[100]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _currentSpeed.toStringAsFixed(0),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
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
    );
  }

  Widget _buildBottomCard() {
    // Determine Time String
    String timeStr = "--";
    DateTime? arrivalTime;

    if (_timeToArrivalSeconds != null) {
      final int minutes = (_timeToArrivalSeconds! / 60).round();
      arrivalTime = DateTime.now().add(Duration(seconds: _timeToArrivalSeconds!.toInt()));

      if (minutes < 60) {
        timeStr = "$minutes min";
      } else {
        final hrs = minutes ~/ 60;
        final mins = minutes % 60;
        timeStr = "${hrs}h ${mins}m";
      }
    } else if (_remainingDistanceKm != null) {
      // Fallback if API didn't return time
      final minutes = (_remainingDistanceKm! / 40 * 60).round(); // Assume 40km/h avg city
      timeStr = "~$minutes min";
      arrivalTime = DateTime.now().add(Duration(minutes: minutes));
    }

    final arrivalStr = arrivalTime != null
        ? "${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}"
        : "--:--";

    final distStr = _remainingDistanceKm != null
        ? "${_remainingDistanceKm!.toStringAsFixed(1)} km"
        : "--";

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(Icons.timer_outlined, timeStr, "Est. Time", primaryColor),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              _buildStatItem(Icons.directions_outlined, distStr, "Distance", darkText),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              _buildStatItem(Icons.schedule, arrivalStr, "Arrival", darkText),
            ],
          ),

          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: accentColor.withOpacity(0.4),
              ),
              onPressed: _hasShownArrivalDialog ? null : _showArrivalDialog,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline),
                  SizedBox(width: 8),
                  Text("Force Arrival", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(icon, size: 20, color: Colors.grey[400]),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}