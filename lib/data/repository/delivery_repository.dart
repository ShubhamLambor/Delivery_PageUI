// lib/data/repository/delivery_repository.dart

import '../../models/delivery_model.dart';

class DeliveryRepository {
  // ✅ Only store real deliveries (removed dummy data completely)
  List<DeliveryModel> _realDeliveries = [];

  /// Get all deliveries (only real data)
  List<DeliveryModel> getAllDeliveries() {
    return _realDeliveries;
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

  /// Add or update a single delivery
  void addOrUpdateOrder(DeliveryModel delivery) {
    final index = _realDeliveries.indexWhere((d) => d.id == delivery.id);
    if (index != -1) {
      _realDeliveries[index] = delivery;
    } else {
      _realDeliveries.add(delivery);
    }
  }

  /// Replace all deliveries with fresh data
  void setDeliveries(List<DeliveryModel> deliveries) {
    _realDeliveries = deliveries;
  }

  /// Clear all deliveries
  void clearDeliveries() {
    _realDeliveries.clear();
  }

  /// Remove specific delivery
  void removeDelivery(String id) {
    _realDeliveries.removeWhere((d) => d.id == id);
  }

  /// Get count of real deliveries
  int get realDeliveryCount => _realDeliveries.length;
}
