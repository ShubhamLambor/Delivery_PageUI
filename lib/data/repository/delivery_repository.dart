// lib/data/repository/delivery_repository.dart

import '../../models/delivery_model.dart';
import 'dummy_data.dart';

class DeliveryRepository {
  // ✅ Store both dummy and real deliveries
  List<DeliveryModel> _realDeliveries = [];
  bool _useRealData = false;

  /// Get all deliveries (real or dummy)
  List<DeliveryModel> getAllDeliveries() {
    return _useRealData ? _realDeliveries : DummyData.deliveries;
  }

  /// Get pending deliveries (New + Pending status)
  List<DeliveryModel> getPendingDeliveries() {
    return getAllDeliveries()
        .where((d) => d.status == 'Pending' || d.status == 'New')
        .toList();
  }

  /// Get completed deliveries
  List<DeliveryModel> getCompletedDeliveries() {
    return getAllDeliveries()
        .where((d) => d.status == 'Completed')
        .toList();
  }

  /// Get cancelled deliveries
  List<DeliveryModel> getCancelledDeliveries() {
    return getAllDeliveries()
        .where((d) => d.status == 'Cancelled' || d.status == 'Rejected')
        .toList();
  }

  /// Get delivery by ID
  DeliveryModel? getDeliveryById(String id) {
    try {
      return getAllDeliveries().firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  /// ✅ NEW: Add or update a single delivery
  void addOrUpdateOrder(DeliveryModel delivery) {
    _useRealData = true;
    final index = _realDeliveries.indexWhere((d) => d.id == delivery.id);
    if (index != -1) {
      _realDeliveries[index] = delivery;
    } else {
      _realDeliveries.add(delivery);
    }
  }

  /// ✅ NEW: Replace all deliveries with fresh data
  void setDeliveries(List<DeliveryModel> deliveries) {
    _useRealData = true;
    _realDeliveries = deliveries;
  }

  /// ✅ NEW: Clear all real deliveries (back to dummy)
  void clearDeliveries() {
    _realDeliveries.clear();
    _useRealData = false;
  }

  /// ✅ NEW: Remove specific delivery
  void removeDelivery(String id) {
    _realDeliveries.removeWhere((d) => d.id == id);
  }

  /// ✅ NEW: Check if using real data
  bool get isUsingRealData => _useRealData;

  /// ✅ NEW: Get count of real deliveries
  int get realDeliveryCount => _realDeliveries.length;
}
