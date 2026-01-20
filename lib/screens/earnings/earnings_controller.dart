// controllers/earnings_controller.dart
import 'package:flutter/material.dart';
import '../../services/earnings_service.dart';

class EarningsController extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  double _totalEarnings = 0;
  int _totalDeliveries = 0;
  double _avgPerDelivery = 0;
  List<Map<String, dynamic>> _recent = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  double get totalEarnings => _totalEarnings;
  int get totalDeliveries => _totalDeliveries;
  double get avgPerDelivery => _avgPerDelivery;
  List<Map<String, dynamic>> get recent => _recent;

  Future fetchEarnings(String partnerId, {String period = 'today'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

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
      } else {
        _error = result['message'] ?? 'Failed to load earnings';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
