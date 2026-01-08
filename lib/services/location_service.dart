// lib/services/location_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

class LocationService {
  Timer? _locationTimer;
  bool _isTracking = false;
  String? _currentPartnerId;

  bool get isTracking => _isTracking;

  /// Start tracking location and sending updates every 30 seconds
  void startLocationTracking(
      String partnerId, {
        Function(String)? onError,
      }) {
    if (_isTracking && _currentPartnerId == partnerId) {
      debugPrint('⚠️ Location tracking already active for: $partnerId');
      return;
    }

    _currentPartnerId = partnerId;
    _isTracking = true;

    debugPrint('🌍 Starting location tracking...');
    debugPrint('🌍 Started location tracking for partner: $partnerId');

    // Send location immediately
    _updateLocation(partnerId, onError);

    // Then send every 30 seconds
    _locationTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _updateLocation(partnerId, onError),
    );
  }

  /// Stop location tracking
  void stopLocationTracking() {
    if (_locationTimer != null) {
      _locationTimer!.cancel();
      _locationTimer = null;
      _isTracking = false;
      _currentPartnerId = null;
      debugPrint('🛑 Location tracking stopped');
    }
  }

  /// Get current location and send to backend
  Future<void> _updateLocation(
      String partnerId,
      Function(String)? onError,
      ) async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission denied');
        onError?.call('Location permission denied');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint('📍 Got location: ${position.latitude}, ${position.longitude}');

      // Send to backend
      debugPrint('📍 Updating location...');
      debugPrint('   Partner ID: $partnerId');
      debugPrint('   Lat: ${position.latitude}, Lng: ${position.longitude}');

      final result = await ApiService.updateLocation(
        partnerId: partnerId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      debugPrint('📥 Location Response Status: ${result['status']}');

      if (result['status'] == 200 || result['success'] == true) {
        debugPrint('✅ Location updated successfully');
      } else {
        debugPrint('⚠️ Location update failed: ${result['message']}');
        onError?.call(result['message'] ?? 'Failed to update location');
      }
    } catch (e) {
      debugPrint('❌ Error updating location: $e');
      onError?.call('Error: $e');
    }
  }

  /// Dispose and cleanup
  void dispose() {
    stopLocationTracking();
  }
}
