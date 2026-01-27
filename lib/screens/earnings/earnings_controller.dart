// controllers/earnings_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/earnings_service.dart';

class EarningsController extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  double _totalEarnings = 0;
  int _totalDeliveries = 0;
  double _avgPerDelivery = 0;
  List<Map<String, dynamic>> _recent = [];

  Timer? _autoRefreshTimer;
  String? _currentPartnerId;
  String _currentPeriod = 'today';

  bool get isLoading => _isLoading;
  String? get error => _error;
  double get totalEarnings => _totalEarnings;
  int get totalDeliveries => _totalDeliveries;
  double get avgPerDelivery => _avgPerDelivery;
  List<Map<String, dynamic>> get recent => _recent;

  // ✅ Start auto-refresh
  void startAutoRefresh(String partnerId, {String period = 'today'}) {
    _currentPartnerId = partnerId;
    _currentPeriod = period;

    // Initial fetch
    fetchEarnings(partnerId, period: period);

    // Auto-refresh every 30 seconds
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      print('🔄 [EARNINGS] Auto-refresh triggered');
      fetchEarnings(partnerId, period: period, silent: true);
    });
  }

  // ✅ Stop auto-refresh
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    print('⏸️ [EARNINGS] Auto-refresh stopped');
  }

  Future fetchEarnings(
      String partnerId, {
        String period = 'today',
        bool silent = false,
      }) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final result = await EarningsService.getPartnerEarnings(
        deliveryPartnerId: partnerId,
        period: period,
      );

      if (result['success'] == true) {
        final stats = result['stats'] ?? {};
        _totalEarnings   = (stats['total_earnings'] ?? 0).toDouble();
        _totalDeliveries = (stats['total_deliveries'] ?? 0) as int;
        _avgPerDelivery  = (stats['avg_per_delivery'] ?? 0).toDouble();
        _recent = (result['recent_deliveries'] as List? ?? [])
            .cast<Map<String, dynamic>>();

        print('✅ [EARNINGS] Loaded: $_totalDeliveries deliveries, ₹$_totalEarnings');
      } else {
        _error = result['message'] ?? 'Failed to load earnings';
      }
    } catch (e) {
      _error = 'Error: $e';
      print('❌ [EARNINGS] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
