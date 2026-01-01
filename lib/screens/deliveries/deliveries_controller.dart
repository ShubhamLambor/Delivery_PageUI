// lib/controllers/deliveries_controller.dart
import 'package:flutter/material.dart';

import '../../data/repository/delivery_repository.dart';
import '../../models/delivery_model.dart';

class DeliveriesController extends ChangeNotifier {
  final DeliveryRepository _repo = DeliveryRepository();

  /// 'All', 'Pending', 'Completed', 'Cancelled'
  String _filter = 'All';
  String get filter => _filter;

  List<DeliveryModel> get _all => _repo.getAllDeliveries();

  List<DeliveryModel> get filteredDeliveries {
    if (_filter == 'All') return _all;
    return _all.where((d) => d.status == _filter).toList();
  }

  int get totalCount => _all.length;
  int get pendingCount =>
      _repo.getPendingDeliveries().length;
  int get completedCount =>
      _repo.getCompletedDeliveries().length;
  int get cancelledCount =>
      _repo.getCancelledDeliveries().length;

  void changeFilter(String value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  DeliveryModel? getById(String id) {
    try {
      return _all.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  void _updateStatus(String id, String newStatus) {
    final list = _repo.getAllDeliveries();
    final index = list.indexWhere((d) => d.id == id);
    if (index == -1) return;

    list[index] = DeliveryModel(
      id: list[index].id,
      customerName: list[index].customerName,
      item: list[index].item,
      address: list[index].address,
      latitude: list[index].latitude,
      longitude: list[index].longitude,
      eta: list[index].eta,
      status: newStatus,
    );
    notifyListeners();
  }

  void markCompleted(String id) => _updateStatus(id, 'Completed');
  void markCancelled(String id) => _updateStatus(id, 'Cancelled');
}
