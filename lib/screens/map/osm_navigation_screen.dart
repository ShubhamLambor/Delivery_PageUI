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
  bool _layersExpanded = false;

  // Navigation Stats
  double _currentSpeed = 0.0;
  double _currentHeading = 0.0;
  double? _remainingDistanceKm;
  double? _timeToArrivalSeconds;

  // Arrival Logic
  bool _canTriggerArrival = false;
  bool _hasShownArrivalDialog = false;
  MapLayer _currentLayer = MapLayer.standard;

  StreamSubscription<Position>? _positionStream;

  // --- Premium UI Colors ---
  static const Color primaryColor = Color(0xFF2E7D32); // Deep Delivery Green
  static const Color routeColor = Color(0xFF2563EB); // Vibrant Route Blue
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

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) setState(() => _canTriggerArrival = true);
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
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) _showErrorSnackBar("Location permission is required.");
          return;
        }
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      if (!mounted) return;

      setState(() {
        _currentLocation = GeoPoint(latitude: pos.latitude, longitude: pos.longitude);
      });

      await mapController.addMarker(
        GeoPoint(latitude: widget.destinationLat, longitude: widget.destinationLng),
        markerIcon: const MarkerIcon(
          icon: Icon(Icons.location_on, color: primaryColor, size: 56),
        ),
      );

      await _calculateRoute();
      _startTracking();
      await mapController.setZoom(zoomLevel: 16);
    } catch (e) {
      debugPrint("❌ Map Init Error: $e");
    }
  }

  Future<void> _calculateRoute() async {
    if (_currentLocation == null) return;
    if (mounted) setState(() => _isLoadingRoute = true);

    try {
      await mapController.removeLastRoad();
    } catch (_) {}

    try {
      _roadInfo = await mapController.drawRoad(
        _currentLocation!,
        GeoPoint(latitude: widget.destinationLat, longitude: widget.destinationLng),
        roadType: RoadType.car,
        roadOption: const RoadOption(
          roadWidth: 14, // Thicker, premium-looking route line
          roadColor: routeColor,
          roadBorderWidth: 4,
          roadBorderColor: Colors.white,
          zoomInto: true,
        ),
      );

      if (_roadInfo != null && mounted) {
        setState(() {
          _remainingDistanceKm = _roadInfo!.distance;
          _timeToArrivalSeconds = _roadInfo!.duration;
        });
      }
    } catch (e) {
      debugPrint("❌ Route Error: $e");
      if (mounted) _showErrorSnackBar("Could not calculate route.");
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  void _startTracking() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: settings)
        .listen((Position pos) {
      if (!mounted) return;

      final newGeo = GeoPoint(latitude: pos.latitude, longitude: pos.longitude);

      setState(() {
        _currentLocation = newGeo;
        _currentSpeed = pos.speed * 3.6;
        _currentHeading = pos.heading;

        final distMeters = Geolocator.distanceBetween(
          pos.latitude, pos.longitude,
          widget.destinationLat, widget.destinationLng,
        );
        _remainingDistanceKm = distMeters / 1000;

        if (_timeToArrivalSeconds != null && _currentSpeed > 5) {
          _timeToArrivalSeconds = (_remainingDistanceKm! / (_currentSpeed / 3600));
        }
      });

      if (!_hasShownArrivalDialog && _canTriggerArrival &&
          _remainingDistanceKm != null && _remainingDistanceKm! < 0.05) {
        _showArrivalDialog();
      }

      if (_isTracking && _isMapReady) {
        mapController.moveTo(newGeo, animate: true);
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
        _layersExpanded = false;
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
        backgroundColor: const Color(0xFFF4FBF7), // Subtle green tint
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: primaryColor, size: 48),
            ),
            const SizedBox(height: 16),
            const Text("You have arrived!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkText, fontFamily: 'Montserrat')),
            const SizedBox(height: 8),
            Text("Destination: ${widget.destinationName}", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontFamily: 'Montserrat')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text("Complete Trip", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Map Layer
          OSMFlutter(
            controller: mapController,
            onMapIsReady: _onMapReady,
            osmOption: OSMOption(
              userTrackingOption: const UserTrackingOption(enableTracking: true, unFollowUser: false),
              zoomOption: const ZoomOption(initZoom: 16, minZoomLevel: 4, maxZoomLevel: 19, stepZoom: 1.0),
              userLocationMarker: UserLocationMaker(
                personMarker: const MarkerIcon(icon: Icon(Icons.navigation, color: routeColor, size: 48)),
                directionArrowMarker: const MarkerIcon(icon: Icon(Icons.navigation, color: routeColor, size: 48)),
              ),
              roadConfiguration: const RoadOption(roadColor: routeColor),
            ),
          ),

          // 2. Top Navigation Bar (With smooth gradient overlay from reference)
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.0)],
                ),
              ),
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 20),
              child: _buildTopBar(),
            ),
          ),

          // 3. Right Side Controls (Layers, Location, Reroute)
          Positioned(
            bottom: 250, right: 16, // Lifted above the bottom sheet
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildLayerControl(),
                const SizedBox(height: 12),
                _buildCircularFAB(
                  heroTag: "reroute",
                  icon: Icons.alt_route_rounded,
                  color: routeColor,
                  isLoading: _isLoadingRoute,
                  onTap: _calculateRoute,
                ),
                const SizedBox(height: 12),
                _buildCircularFAB(
                  heroTag: "recenter",
                  icon: _isTracking ? Icons.my_location : Icons.location_searching,
                  color: _isTracking ? routeColor : Colors.grey.shade600,
                  onTap: _recenter,
                ),
                const SizedBox(height: 12),
                if (_currentSpeed > 2) _buildSpeedBadge(),
              ],
            ),
          ),

          // 4. Bottom Info Sheet (Sleek design)
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomCard()),
        ],
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildTopBar() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Navigating to", style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'Montserrat')),
                Text(widget.destinationName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: darkText, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.location_on, size: 18, color: primaryColor),
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
          _layerOption(MapLayer.satellite, Icons.satellite_alt_rounded),
          const SizedBox(height: 8),
          _layerOption(MapLayer.terrain, Icons.terrain_rounded),
          const SizedBox(height: 8),
          _layerOption(MapLayer.standard, Icons.map_rounded),
          const SizedBox(height: 8),
        ],
        _buildCircularFAB(
          heroTag: "layers_toggle",
          icon: _layersExpanded ? Icons.close_rounded : Icons.layers_rounded,
          color: darkText,
          onTap: () => setState(() => _layersExpanded = !_layersExpanded),
        )
      ],
    );
  }

  Widget _layerOption(MapLayer layer, IconData icon) {
    final isSelected = _currentLayer == layer;
    return GestureDetector(
      onTap: () => _switchLayer(layer),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : surfaceColor,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.grey[700]),
      ),
    );
  }

  Widget _buildCircularFAB({required String heroTag, required IconData icon, required Color color, required VoidCallback onTap, bool isLoading = false}) {
    return FloatingActionButton(
      heroTag: heroTag,
      mini: true,
      backgroundColor: surfaceColor,
      elevation: 4,
      shape: const CircleBorder(),
      onPressed: onTap,
      child: isLoading
          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: color))
          : Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildSpeedBadge() {
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        color: surfaceColor, shape: BoxShape.circle, border: Border.all(color: Colors.grey[100]!, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_currentSpeed.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: darkText, height: 1.0)),
          const Text("km/h", style: TextStyle(fontSize: 9, color: Colors.grey, height: 1.0))
        ],
      ),
    );
  }

  Widget _buildBottomCard() {
    String timeStr = "--";
    DateTime? arrivalTime;

    if (_timeToArrivalSeconds != null) {
      final int minutes = (_timeToArrivalSeconds! / 60).round();
      arrivalTime = DateTime.now().add(Duration(seconds: _timeToArrivalSeconds!.toInt()));
      timeStr = minutes < 60 ? "$minutes min" : "${minutes ~/ 60}h ${minutes % 60}m";
    } else if (_remainingDistanceKm != null) {
      final minutes = (_remainingDistanceKm! / 40 * 60).round();
      timeStr = "~$minutes min";
      arrivalTime = DateTime.now().add(Duration(minutes: minutes));
    }

    final arrivalStr = arrivalTime != null ? "${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}" : "--:--";
    final distStr = _remainingDistanceKm != null ? "${_remainingDistanceKm!.toStringAsFixed(1)} km" : "--";

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(Icons.timer_outlined, timeStr, "Est. Time", primaryColor),
              Container(width: 1, height: 36, color: Colors.grey[200]),
              _buildStatItem(Icons.directions_outlined, distStr, "Distance", darkText),
              Container(width: 1, height: 36, color: Colors.grey[200]),
              _buildStatItem(Icons.schedule, arrivalStr, "Arrival", darkText),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: primaryColor.withOpacity(0.3),
              ),
              onPressed: _hasShownArrivalDialog ? null : _showArrivalDialog,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 22),
                  SizedBox(width: 8),
                  Text("Force Arrival", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
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
            Icon(icon, size: 18, color: Colors.grey[400]),
            const SizedBox(width: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600, fontFamily: 'Montserrat')),
      ],
    );
  }
}