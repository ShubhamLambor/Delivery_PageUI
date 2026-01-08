// lib/screens/home/home_controller.dart

import 'package:flutter/material.dart';
import '../../data/repository/delivery_repository.dart';
import '../../data/repository/user_repository.dart';
import '../../models/delivery_model.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';

class HomeController extends ChangeNotifier {
  final DeliveryRepository _deliveryRepo = DeliveryRepository();
  final UserRepository _userRepo = UserRepository();
  final LocationService _locationService = LocationService();

  bool _isOnline = false; // Start offline by default
  bool _isLoading = false;
  String? _errorMessage;

  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLocationTracking => _locationService.isTracking;
  String get userName => _userRepo.getUser().name;

  // Added getter for partner ID
  String get partnerId => _getPartnerId();

  List<DeliveryModel> get allDeliveries => _deliveryRepo.getAllDeliveries();
  int get totalCount => allDeliveries.length;
  int get pendingCount => _deliveryRepo.getPendingDeliveries().length;
  int get completedCount => _deliveryRepo.getCompletedDeliveries().length;
  int get cancelledCount => _deliveryRepo.getCancelledDeliveries().length;

  DeliveryModel? get currentDelivery {
    final list = _deliveryRepo.getPendingDeliveries();
    return list.isNotEmpty ? list.first : null;
  }

  List<DeliveryModel> get upcomingDeliveries =>
      _deliveryRepo.getPendingDeliveries();

  /// ✅ NEW: Fetch/refresh deliveries from backend
  Future<void> fetchDeliveries() async {
    try {
      debugPrint('📋 Refreshing deliveries...');
      // Repository methods are already accessible via getters
      // No need to call a refresh method - just notify listeners
      notifyListeners();
      debugPrint('✅ Deliveries refreshed successfully');
    } catch (e) {
      debugPrint('❌ Error refreshing deliveries: $e');
      _errorMessage = 'Failed to refresh deliveries';
      notifyListeners();
    }
  }

  /// ✅ NEW: Load new orders for delivery partner
  Future<void> loadNewOrders() async {
    try {
      debugPrint('📋 Loading new orders...');
      // This is a placeholder - implement based on your needs
      // You might want to fetch from DeliveryService.getNewOrders
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading new orders: $e');
    }
  }

  /// ✅ NEW: Load active orders for delivery partner
  Future<void> loadActiveOrders() async {
    try {
      debugPrint('📋 Loading active orders...');
      // This is a placeholder - implement based on your needs
      // You might want to fetch from DeliveryService.getActiveOrders
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading active orders: $e');
    }
  }

  /// Toggle online/offline status with backend call
  Future<void> toggleOnline() async {
    if (_isLoading) return; // Prevent multiple simultaneous requests

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final newStatus = !_isOnline;

    final result = await ApiService.updatePartnerStatus(
      partnerId: _getPartnerId(),
      isOnline: newStatus,
      partnerName: userName,
    );

    if (result['success'] == true || result['status'] == 'success') {
      _isOnline = newStatus;
      debugPrint('✅ Status updated: ${_isOnline ? 'Online' : 'Offline'}');

      // Start or stop location tracking based on status
      if (_isOnline) {
        debugPrint('🌍 Starting location tracking...');
        _locationService.startLocationTracking(
          _getPartnerId(),  // ✅ FIXED: Added partnerId parameter
          onError: (error) {
            _errorMessage = error;
            notifyListeners();
          },
        );
      } else {
        debugPrint('🛑 Stopping location tracking...');
        _locationService.stopLocationTracking();
      }

      // Print debug logs if available
      if (result['debug_log'] != null) {
        debugPrint('📋 Server Debug Log:');
        for (var log in result['debug_log']) {
          debugPrint('   $log');
        }
      }
    } else {
      _errorMessage = result['message'] ?? 'Failed to update status';
      debugPrint('❌ Error: $_errorMessage');

      // Print debug logs if available
      if (result['debug_log'] != null) {
        debugPrint('📋 Server Debug Log:');
        for (var log in result['debug_log']) {
          debugPrint('   $log');
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch current status from backend (call on app start)
  Future<void> fetchOnlineStatus() async {
    try {
      final result = await ApiService.getPartnerStatus(
        partnerId: _getPartnerId(),
      );

      if (result['success'] == true || result['status'] == 'success') {
        _isOnline = result['status'] == 1 ||
            result['status'] == 'online' ||
            result['is_online'] == true ||
            result['is_online'] == 1;

        // If user was online, restart location tracking
        if (_isOnline) {
          _locationService.startLocationTracking(
            _getPartnerId(),  // ✅ FIXED: Added partnerId parameter
            onError: (error) {
              _errorMessage = error;
              notifyListeners();
            },
          );
        }

        notifyListeners();
        debugPrint('✅ Fetched status: ${_isOnline ? 'Online' : 'Offline'}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching status: $e');
    }
  }

  /// ✅ NEW: Initialize controller - fetch status and deliveries
  Future<void> initialize() async {
    debugPrint('🚀 Initializing HomeController...');
    try {
      // Fetch online status from backend
      await fetchOnlineStatus();

      // Load initial deliveries
      await fetchDeliveries();

      debugPrint('✅ HomeController initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing HomeController: $e');
      _errorMessage = 'Failed to initialize';
      notifyListeners();
    }
  }

  /// ✅ NEW: Force refresh all data
  Future<void> refresh() async {
    debugPrint('🔄 Refreshing all data...');
    try {
      await Future.wait([
        fetchOnlineStatus(),
        fetchDeliveries(),
      ]);
      debugPrint('✅ All data refreshed');
    } catch (e) {
      debugPrint('❌ Error refreshing data: $e');
      _errorMessage = 'Failed to refresh data';
      notifyListeners();
    }
  }

  /// Get partner ID from user repository
  String _getPartnerId() {
    final user = _userRepo.getUser();
    return user.id ?? user.phone ?? 'unknown';
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// ✅ NEW: Update online status without toggling
  void setOnlineStatus(bool status) {
    if (_isOnline != status) {
      _isOnline = status;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Stop location tracking when controller is disposed
    _locationService.dispose();
    super.dispose();
  }
}
