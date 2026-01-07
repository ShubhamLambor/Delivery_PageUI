// lib/services/location_service.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'api_service.dart';

class LocationService {
  Timer? _locationTimer;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  /// Start tracking location (call when user goes online)
  void startLocationTracking({
    required String partnerId,
    required Function(String) onError,
  }) {
    if (_isTracking) {
      debugPrint('⚠️ Location tracking already active');
      return;
    }

    _isTracking = true;
    debugPrint('🌍 Started location tracking for partner: $partnerId');

    // Send immediate location update
    _sendLocationUpdate(partnerId, onError);

    // Update location every 30 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _sendLocationUpdate(partnerId, onError);
    });
  }

  /// Stop tracking location (call when user goes offline)
  void stopLocationTracking() {
    if (_locationTimer != null) {
      _locationTimer!.cancel();
      _locationTimer = null;
      _isTracking = false;
      debugPrint('🛑 Stopped location tracking');
    }
  }

  /// Send location update to backend
  Future<void> _sendLocationUpdate(
      String partnerId,
      Function(String) onError,
      ) async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission denied');
        onError('Location permission required');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint('📍 Got location: ${position.latitude}, ${position.longitude}');

      // Send to backend
      final result = await ApiService.updateLocation(
        partnerId: partnerId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (result['success'] != true) {
        debugPrint('⚠️ Location update failed: ${result['message']}');

        // If user went offline, stop tracking
        if (result['is_online'] == 0 || result['is_online'] == false) {
          debugPrint('🛑 User is offline, stopping location tracking');
          stopLocationTracking();
        }
      }
    } catch (e) {
      debugPrint('❌ Location update error: $e');
      // Don't stop tracking on temporary errors
      if (e is TimeoutException) {
        debugPrint('⏱️ Location timeout, will retry next cycle');
      }
    }
  }

  /// Dispose method to clean up
  void dispose() {
    stopLocationTracking();
  }
}
