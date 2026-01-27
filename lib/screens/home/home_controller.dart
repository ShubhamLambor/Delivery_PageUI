// lib/screens/home/home_controller.dart

import 'package:flutter/material.dart';
import 'dart:async';  // ✅ ADD THIS
import '../../models/delivery_model.dart';
import '../../services/delivery_service.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';

class HomeController extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  Timer? _pollingTimer;  // ✅ ADD THIS

  // REAL DATA from backend
  List<DeliveryModel> _allDeliveries = [];
  bool _isOnline = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _partnerId;

  // ✅ Partner stats from backend
  int _todayEarnings = 0;
  int _completedToday = 0;
  int _pendingToday = 0;
  int _cancelledToday = 0;

  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLocationTracking => _locationService.isTracking;
  String? get partnerId => _partnerId;

  List<DeliveryModel> get allDeliveries => _allDeliveries;
  int get totalCount => _allDeliveries.length;
  int get todayEarnings => _todayEarnings;

  int get pendingCount => _pendingToday > 0
      ? _pendingToday
      : _allDeliveries.where((d) => d.status.toLowerCase() == 'pending').length;

  int get completedCount => _completedToday > 0
      ? _completedToday
      : _allDeliveries.where((d) => d.status.toLowerCase() == 'delivered').length;

  int get cancelledCount => _cancelledToday > 0
      ? _cancelledToday
      : _allDeliveries.where((d) => d.status.toLowerCase() == 'cancelled').length;

  /// Current active delivery
  DeliveryModel? get currentDelivery {
    debugPrint('═══════════════════════════════════════');
    debugPrint('🟢 CURRENT DELIVERY GETTER CALLED:');
    debugPrint('   All deliveries count: ${_allDeliveries.length}');
    if (_allDeliveries.isEmpty) {
      debugPrint('   ❌ NO DELIVERIES IN LIST');
      debugPrint('═══════════════════════════════════════');
      return null;
    }

    for (var d in _allDeliveries) {
      debugPrint('   📦 Delivery ${d.id}: status="${d.status}"');
    }

    final current = _allDeliveries.where((d) {
      final status = d.status.toLowerCase().trim();
      return status == 'assigned' ||        // ✅ ADD THIS LINE
          status == 'accepted' ||
          status == 'confirmed' ||
          status == 'picked_up' ||
          status == 'in_transit' ||
          status == 'ready' ||
          status == 'waiting_for_order' ||
          status == 'waiting_for_pickup' ||
          status == 'ready_for_pickup' ||
          status == 'at_pickup_location' ||
          status == 'out_for_delivery';
    }).toList();

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

  /// Upcoming deliveries
  List<DeliveryModel> get upcomingDeliveries {
    return _allDeliveries
        .where((d) {
      final status = d.status.toLowerCase().trim();
      return status == 'accepted' || status == 'ready' || status == 'ready_for_pickup';
    })
        .skip(1)
        .toList();
  }

  /// Set partner ID
  void setPartnerId(String id) {
    _partnerId = id;
    debugPrint('✅ [HOME_CONTROLLER] Partner ID set: $id');
  }

  /// ✅ NEW: Start polling for new orders every 5 seconds
  void startPolling() {
    if (_partnerId == null || _partnerId!.isEmpty) {
      debugPrint('❌ [HOME_CONTROLLER] Cannot start polling: Partner ID is null');
      return;
    }

    stopPolling();

    debugPrint('🔄 [HOME_CONTROLLER] Starting order polling (every 5 seconds)');
    debugPrint('   Partner ID: $_partnerId');
    debugPrint('   Is Online: $_isOnline');

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      debugPrint('⏰ [HOME_CONTROLLER] Polling tick #${timer.tick}');

      if (_isOnline && _partnerId != null) {
        debugPrint('   ✅ Fetching deliveries...');
        fetchDeliveries();
      } else {
        debugPrint('   ⏸️ Skipping poll (offline or no partner ID)');
      }
    });

    debugPrint('✅ [HOME_CONTROLLER] Timer created: ${_pollingTimer?.isActive}');
  }

  /// ✅ NEW: Stop polling
  void stopPolling() {
    if (_pollingTimer != null) {
      _pollingTimer!.cancel();
      _pollingTimer = null;
      debugPrint('⏹️ [HOME_CONTROLLER] Polling stopped');
    }
  }

  /// Fetch partner stats from backend
  Future<void> fetchPartnerStats() async {
    if (_partnerId == null || _partnerId!.isEmpty) {
      debugPrint('❌ [HOME_CONTROLLER] Cannot fetch stats: Partner ID is null');
      return;
    }

    try {
      debugPrint('📊 [HOME_CONTROLLER] Fetching partner stats...');
      final result = await DeliveryService.getPartnerStats(
        deliveryPartnerId: _partnerId!,
      );

      if (result['success'] == true && result['stats'] != null) {
        final stats = result['stats'];

        // ✅ Handle both int and double values
        _todayEarnings = ((stats['todayearnings'] ?? 0) as num).toInt();
        _completedToday = (stats['completedtoday'] ?? 0) as int;
        _pendingToday = (stats['pendingtoday'] ?? 0) as int;
        _cancelledToday = (stats['cancelledtoday'] ?? 0) as int;

        debugPrint('✅ [HOME_CONTROLLER] Stats fetched successfully:');
        debugPrint('   Today Earnings: ₹$_todayEarnings');
        debugPrint('   Completed: $_completedToday');
        debugPrint('   Pending: $_pendingToday');
        debugPrint('   Cancelled: $_cancelledToday');

        notifyListeners();
      } else {
        debugPrint('⚠️ [HOME_CONTROLLER] Stats not available from backend');
      }
    } catch (e) {
      debugPrint('❌ [HOME_CONTROLLER] Error fetching stats: $e');
    }
  }


  /// Fetch deliveries from backend
  Future<void> fetchDeliveries() async {
    if (_partnerId == null || _partnerId!.isEmpty) {
      debugPrint('❌ [HOME_CONTROLLER] Cannot fetch: Partner ID is null');
      return;
    }

    try {
      debugPrint('📋 [HOME_CONTROLLER] Fetching deliveries for partner: $_partnerId');
      final data = await DeliveryService.getActiveDeliveries(_partnerId!);
      debugPrint('═══════════════════════════════════════');
      debugPrint('🔵 [HOME_CONTROLLER] FETCHED DELIVERIES FROM API:');
      debugPrint('   Total count: ${data.length}');
      if (data.isEmpty) {
        debugPrint('   ⚠️ No deliveries returned from API');
      } else {
        for (var delivery in data) {
          debugPrint('   📦 Order ${delivery.id}: ${delivery.status}');
        }
      }
      _allDeliveries = data;
      debugPrint('   ✅ Updated _allDeliveries list with ${_allDeliveries.length} items');
      debugPrint('═══════════════════════════════════════');
      _errorMessage = null;
      notifyListeners();
      debugPrint('✅ [HOME_CONTROLLER] Deliveries fetched and notified');
    } catch (e, stackTrace) {
      debugPrint('❌ [HOME_CONTROLLER] Error fetching deliveries: $e');
      debugPrint('   Stack trace: $stackTrace');
      _errorMessage = 'Failed to fetch deliveries';
      _allDeliveries = [];
      notifyListeners();
    }
  }

  /// Toggle online/offline status
  Future<void> toggleOnline() async {
    if (_isLoading) return;
    if (_partnerId == null || _partnerId!.isEmpty) {
      debugPrint('❌ Cannot toggle: Partner ID is null');
      return;
    }

    final newStatus = !_isOnline;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔄 Sending status update...');
      debugPrint('   Partner ID: $_partnerId');
      debugPrint('   Status: ${newStatus ? 1 : 0}');
      debugPrint('═══════════════════════════════════════');

      final result = await ApiService.updatePartnerStatus(
        partnerId: _partnerId!,
        isOnline: newStatus,
        partnerName: 'Delivery Partner',
      );

      if (result['success'] == true || result['status'] == 'success') {
        _isOnline = newStatus;
        debugPrint('✅ Status updated: ${_isOnline ? 'Online' : 'Offline'}');

        if (_isOnline) {
          debugPrint('🌍 Starting location tracking...');
          _locationService.startLocationTracking(
            _partnerId!,
            onError: (error) {
              _errorMessage = error;
              notifyListeners();
            },
          );

          // ✅ START POLLING
          startPolling();

          await fetchDeliveries();
          await fetchPartnerStats();
        } else {
          debugPrint('🛑 Stopping location tracking...');
          _locationService.stopLocationTracking();

          // ✅ STOP POLLING
          stopPolling();
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
      debugPrint('🔄 Fetching status for partner: $_partnerId');
      final result = await ApiService.getPartnerStatus(
        partnerId: _partnerId!,
      );

      if (result['success'] == true || result['status'] == 'success') {
        final statusValue = result['is_online'] ?? result['status'];
        _isOnline = statusValue == 1 ||
            statusValue == '1' ||
            statusValue == true ||
            statusValue == 'online';
        debugPrint('✅ Fetched status: ${_isOnline ? 'Online' : 'Offline'}');

        if (_isOnline) {
          debugPrint('🌍 Starting location tracking...');
          _locationService.startLocationTracking(
            _partnerId!,
            onError: (error) {
              _errorMessage = error;
              notifyListeners();
            },
          );

          // ✅ START POLLING if already online
          startPolling();
          debugPrint('✅ Polling started after fetching status');
        } else {
          _locationService.stopLocationTracking();
          stopPolling();
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error fetching status: $e');
    }
  }

  /// Initialize controller
  Future<void> initialize(String partnerId) async {
    debugPrint('🚀 [HOME_CONTROLLER] Initializing for partner: $partnerId');
    _partnerId = partnerId;
    try {
      await fetchOnlineStatus();
      await fetchDeliveries();
      await fetchPartnerStats();
      debugPrint('✅ [HOME_CONTROLLER] Initialized successfully');
      debugPrint('   Final delivery count: ${_allDeliveries.length}');
      debugPrint('   Is Online: $_isOnline');
      debugPrint('   Polling Active: ${_pollingTimer?.isActive ?? false}');
    } catch (e) {
      debugPrint('❌ [HOME_CONTROLLER] Error initializing: $e');
      _errorMessage = 'Failed to initialize';
      notifyListeners();
    }
  }

  /// Force refresh all data
  Future<void> refresh() async {
    debugPrint('🔄 [HOME_CONTROLLER] Refreshing all data...');
    try {
      await fetchOnlineStatus();
      await fetchDeliveries();
      await fetchPartnerStats();
      debugPrint('✅ [HOME_CONTROLLER] All data refreshed');
    } catch (e) {
      debugPrint('❌ [HOME_CONTROLLER] Error refreshing data: $e');
      _errorMessage = 'Failed to refresh data';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setOnlineStatus(bool status) {
    if (_isOnline != status) {
      _isOnline = status;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopPolling();  // ✅ STOP POLLING on dispose
    _locationService.dispose();
    super.dispose();
  }
}
