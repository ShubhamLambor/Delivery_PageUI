// lib/screens/home/home_controller.dart

import 'package:flutter/material.dart';
import '../../models/delivery_model.dart';
import '../../services/delivery_service.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';

class HomeController extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  // ✅ REAL DATA from backend
  List<DeliveryModel> _allDeliveries = [];

  bool _isOnline = false; // Start offline by default
  bool _isLoading = false;
  String? _errorMessage;
  String? _partnerId;

  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLocationTracking => _locationService.isTracking;

  // ✅ Real getters from backend data
  List<DeliveryModel> get allDeliveries => _allDeliveries;
  int get totalCount => _allDeliveries.length;

  int get pendingCount => _allDeliveries
      .where((d) => d.status.toLowerCase() == 'pending')
      .length;

  int get completedCount => _allDeliveries
      .where((d) => d.status.toLowerCase() == 'delivered')
      .length;

  int get cancelledCount => _allDeliveries
      .where((d) => d.status.toLowerCase() == 'cancelled')
      .length;

  /// ✅ FIXED: Get current active delivery (accepted/picked_up/in_transit)
  DeliveryModel? get currentDelivery {
    final current = _allDeliveries.where((d) {
      final status = d.status.toLowerCase();
      return status == 'accepted' ||
          status == 'picked_up' ||
          status == 'in_transit';
    }).toList();

    // 🔵 DEBUG
    debugPrint('═══════════════════════════════════════');
    debugPrint('🟢 CURRENT DELIVERY GETTER CALLED:');
    debugPrint('   All deliveries count: ${_allDeliveries.length}');
    debugPrint('   Filtered current count: ${current.length}');

    if (current.isNotEmpty) {
      debugPrint('   ✅ FOUND CURRENT DELIVERY:');
      debugPrint('      ID: ${current.first.id}');
      debugPrint('      Status: ${current.first.status}');
      debugPrint('      Customer: ${current.first.customerName}');
    } else {
      debugPrint('   ❌ NO CURRENT DELIVERY FOUND');
    }
    debugPrint('═══════════════════════════════════════');

    return current.isNotEmpty ? current.first : null;
  }

  /// ✅ Get upcoming deliveries (accepted status, not yet picked up)
  List<DeliveryModel> get upcomingDeliveries {
    return _allDeliveries
        .where((d) => d.status.toLowerCase() == 'accepted')
        .skip(1) // Skip the first one (shown in current)
        .toList();
  }

  /// ✅ Set partner ID
  void setPartnerId(String id) {
    _partnerId = id;
    debugPrint('✅ Partner ID set: $id');
  }

  /// ✅ Fetch deliveries from backend
  Future<void> fetchDeliveries() async {
    if (_partnerId == null || _partnerId!.isEmpty) {
      debugPrint('❌ Cannot fetch: Partner ID is null');
      return;
    }

    try {
      debugPrint('📋 Fetching deliveries for partner: $_partnerId');

      final data = await DeliveryService.getActiveDeliveries(_partnerId!);

      // 🔵 DEBUG
      debugPrint('═══════════════════════════════════════');
      debugPrint('🔵 FETCHED DELIVERIES FROM API:');
      debugPrint('   Total count: ${data.length}');

      _allDeliveries = data;

      // 🔵 DEBUG each delivery
      for (var delivery in _allDeliveries) {
        debugPrint('   - Order ${delivery.id}: ${delivery.status}');
      }
      debugPrint('═══════════════════════════════════════');

      _errorMessage = null;
      notifyListeners();
      debugPrint('✅ Deliveries fetched successfully');
    } catch (e) {
      debugPrint('❌ Error fetching deliveries: $e');
      _errorMessage = 'Failed to fetch deliveries';
      notifyListeners();
    }
  }

  /// Toggle online/offline status with backend call
  Future<void> toggleOnline() async {
    if (_isLoading) return;
    if (_partnerId == null || _partnerId!.isEmpty) {
      debugPrint('❌ Cannot toggle: Partner ID is null');
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final newStatus = !_isOnline;

    try {
      final result = await ApiService.updatePartnerStatus(
        partnerId: _partnerId!,
        isOnline: newStatus,
        partnerName: 'Delivery Partner', // You can pass actual name here
      );

      if (result['success'] == true || result['status'] == 'success') {
        _isOnline = newStatus;
        debugPrint('✅ Status updated: ${_isOnline ? 'Online' : 'Offline'}');

        // Start or stop location tracking
        if (_isOnline) {
          debugPrint('🌍 Starting location tracking...');
          _locationService.startLocationTracking(
            _partnerId!,
            onError: (error) {
              _errorMessage = error;
              notifyListeners();
            },
          );
        } else {
          debugPrint('🛑 Stopping location tracking...');
          _locationService.stopLocationTracking();
        }
      } else {
        _errorMessage = result['message'] ?? 'Failed to update status';
        debugPrint('❌ Error: $_errorMessage');
      }
    } catch (e) {
      debugPrint('❌ Error toggling status: $e');
      _errorMessage = 'Failed to update status';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch current status from backend
  Future<void> fetchOnlineStatus() async {
    if (_partnerId == null || _partnerId!.isEmpty) {
      debugPrint('❌ Cannot fetch status: Partner ID is null');
      return;
    }

    try {
      final result = await ApiService.getPartnerStatus(
        partnerId: _partnerId!,
      );

      if (result['success'] == true || result['status'] == 'success') {
        _isOnline = result['status'] == 1 ||
            result['status'] == 'online' ||
            result['is_online'] == true ||
            result['is_online'] == 1;

        // If user was online, restart location tracking
        if (_isOnline) {
          _locationService.startLocationTracking(
            _partnerId!,
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

  /// ✅ Initialize controller - fetch status and deliveries
  Future<void> initialize(String partnerId) async {
    debugPrint('🚀 Initializing HomeController for partner: $partnerId');

    _partnerId = partnerId;

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

  /// ✅ Force refresh all data
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

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// ✅ Update online status without toggling
  void setOnlineStatus(bool status) {
    if (_isOnline != status) {
      _isOnline = status;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }
}
