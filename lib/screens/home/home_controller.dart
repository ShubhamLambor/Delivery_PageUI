// lib/screens/home/home_controller.dart

import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/delivery_model.dart';
import '../../services/delivery_service.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';

class HomeController extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  Timer? _pollingTimer;

  // REAL DATA from backend
  List<DeliveryModel> _allDeliveries = [];
  bool _isOnline = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _partnerId;

  // Partner stats from backend
  int _todayEarnings = 0;
  int _completedToday = 0;
  int _pendingToday = 0;
  int _cancelledToday = 0;

  // Track which new orders we already showed popup for
  final Set<String> _shownNewOrderIds = {};

  // Optional: expose a stream/callback for UI to listen to new-order events
  final StreamController<Map<String, dynamic>> _newOrderController =
  StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get newOrderStream =>
      _newOrderController.stream;

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
      : _allDeliveries
      .where((d) => d.status.toLowerCase() == 'pending')
      .length;

  int get completedCount => _completedToday > 0
      ? _completedToday
      : _allDeliveries
      .where((d) => d.status.toLowerCase() == 'delivered')
      .length;

  int get cancelledCount => _cancelledToday > 0
      ? _cancelledToday
      : _allDeliveries
      .where((d) => d.status.toLowerCase() == 'cancelled')
      .length;

  /// 🚨 FIXED: Current active delivery logic
  DeliveryModel? get currentDelivery {
    debugPrint('═══════════════════════════════════════');
    debugPrint('🟢 CURRENT DELIVERY GETTER CALLED:');
    if (_allDeliveries.isEmpty) {
      return null;
    }

    final current = _allDeliveries.where((d) {
      final aStatus = d.assignmentStatus.toLowerCase().trim();
      final oStatus = d.status.toLowerCase().trim();

      // 🚨 CRITICAL FIX: If the assignment is still 'assigned' or 'pending',
      // it means the popup is currently showing and the driver HAS NOT ACCEPTED IT YET.
      // We must explicitly hide it from the "Current Delivery" banner!
      if (aStatus == 'assigned' || aStatus == 'pending' || aStatus == 'rejected') {
        return false;
      }

      // STRICT CHECK: The delivery partner MUST have explicitly accepted the order.
      final isActiveAssignment =
          aStatus == 'accepted' ||
              aStatus == 'at_pickup' ||
              aStatus == 'at_pickup_location' ||
              aStatus == 'picked_up' ||
              aStatus == 'in_transit';

      // Fallback in case backend sets the main status to accepted
      final isActiveOrder =
          oStatus == 'accepted' ||
              oStatus == 'at_pickup' ||
              oStatus == 'picked_up' ||
              oStatus == 'in_transit' ||
              oStatus == 'out_for_delivery';

      return isActiveAssignment || isActiveOrder;
    }).toList();

    return current.isNotEmpty ? current.first : null;
  }

  /// Upcoming deliveries
  List<DeliveryModel> get upcomingDeliveries {
    return _allDeliveries
        .where((d) {
      final aStatus = d.assignmentStatus.toLowerCase().trim();
      return aStatus == 'accepted';
    })
        .skip(1)
        .toList();
  }

  /// Set partner ID
  void setPartnerId(String id) {
    _partnerId = id;
    debugPrint('✅ [HOME_CONTROLLER] Partner ID set: $id');
  }

  /// Start polling for active + new orders
  void startPolling() {
    if (_partnerId == null || _partnerId!.isEmpty) {
      debugPrint('❌ [HOME_CONTROLLER] Cannot start polling: Partner ID is null');
      return;
    }

    stopPolling();

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_isOnline && _partnerId != null && _partnerId!.isNotEmpty) {
        await fetchDeliveries();
        await _pollNewOrders();
      }
    });
  }

  /// Stop polling
  void stopPolling() {
    if (_pollingTimer != null) {
      _pollingTimer!.cancel();
      _pollingTimer = null;
    }
  }

  /// Poll get_new_orders.php and emit events for UI to show popup
  Future<void> _pollNewOrders() async {
    if (_partnerId == null || _partnerId!.isEmpty) {
      return;
    }

    try {
      final result = await DeliveryService.getNewOrders(
        deliveryPartnerId: _partnerId!,
      );

      if (result['success'] == true) {
        final List orders = result['orders'] ?? [];
        for (final o in orders) {
          final orderId = (o['order_id'] ?? o['id'])?.toString();
          final status = o['status']?.toString().toLowerCase().trim();

          if (orderId == null) continue;

          if ((status == 'assigned' || status == 'confirmed') &&
              !_shownNewOrderIds.contains(orderId)) {
            _shownNewOrderIds.add(orderId);
            _newOrderController.add(o as Map<String, dynamic>);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [HOME_CONTROLLER] Error polling new orders: $e');
    }
  }

  /// Fetch partner stats from backend
  Future<void> fetchPartnerStats() async {
    if (_partnerId == null || _partnerId!.isEmpty) return;

    try {
      final result = await DeliveryService.getPartnerStats(
        deliveryPartnerId: _partnerId!,
      );

      if (result['success'] == true && result['stats'] != null) {
        final stats = result['stats'];

        _todayEarnings = ((stats['todayearnings'] ?? 0) as num).toInt();
        _completedToday = (stats['completedtoday'] ?? 0) as int;
        _pendingToday = (stats['pendingtoday'] ?? 0) as int;
        _cancelledToday = (stats['cancelledtoday'] ?? 0) as int;

        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ [HOME_CONTROLLER] Error fetching stats: $e');
    }
  }

  /// Fetch deliveries from backend
  Future<void> fetchDeliveries() async {
    if (_partnerId == null || _partnerId!.isEmpty) return;

    try {
      final data = await DeliveryService.getActiveDeliveries(_partnerId!);
      _allDeliveries = data;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch deliveries';
      _allDeliveries = [];
      notifyListeners();
    }
  }

  /// Toggle online/offline status
  Future<void> toggleOnline() async {
    if (_isLoading) return;
    if (_partnerId == null || _partnerId!.isEmpty) return;

    final newStatus = !_isOnline;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.updatePartnerStatus(
        partnerId: _partnerId!,
        isOnline: newStatus,
        partnerName: 'Delivery Partner',
      );

      if (result['success'] == true || result['status'] == 'success') {
        _isOnline = newStatus;

        if (_isOnline) {
          _locationService.startLocationTracking(
            _partnerId!,
            onError: (error) {
              _errorMessage = error;
              notifyListeners();
            },
          );
          startPolling();
          await fetchDeliveries();
          await fetchPartnerStats();
        } else {
          _locationService.stopLocationTracking();
          stopPolling();
        }
      } else {
        _errorMessage = result['message'] ?? 'Failed to update status';
      }
    } catch (e) {
      _errorMessage = 'Failed to update status';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch current status from backend
  Future<void> fetchOnlineStatus() async {
    if (_partnerId == null || _partnerId!.isEmpty) return;

    try {
      final result = await ApiService.getPartnerStatus(
        partnerId: _partnerId!,
      );

      if (result['success'] == true || result['status'] == 'success') {
        final statusValue = result['is_online'] ?? result['status'];
        _isOnline = statusValue == 1 ||
            statusValue == '1' ||
            statusValue == true ||
            statusValue == 'online';

        if (_isOnline) {
          _locationService.startLocationTracking(
            _partnerId!,
            onError: (error) {
              _errorMessage = error;
              notifyListeners();
            },
          );
          startPolling();
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
    _partnerId = partnerId;
    try {
      await fetchOnlineStatus();
      await fetchDeliveries();
      await fetchPartnerStats();
    } catch (e) {
      _errorMessage = 'Failed to initialize';
      notifyListeners();
    }
  }

  /// Force refresh all data
  Future<void> refresh() async {
    try {
      await fetchOnlineStatus();
      await fetchDeliveries();
      await fetchPartnerStats();
    } catch (e) {
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
    stopPolling();
    _locationService.dispose();
    _newOrderController.close();
    super.dispose();
  }
}