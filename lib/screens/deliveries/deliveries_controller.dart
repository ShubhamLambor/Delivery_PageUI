// lib/controllers/deliveries_controller.dart
import 'package:flutter/material.dart';

import '../../data/repository/delivery_repository.dart';
import '../../models/delivery_model.dart';
import '../../services/delivery_service.dart';
import '../auth/auth_controller.dart';

class DeliveriesController extends ChangeNotifier {
  final DeliveryRepository _repo = DeliveryRepository();
  final AuthController? _authController;

  DeliveriesController({AuthController? authController})
      : _authController = authController;

  /// 'All', 'New', 'Pending', 'Completed', 'Cancelled'
  String _filter = 'All';
  String get filter => _filter;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<DeliveryModel> get _all => _repo.getAllDeliveries();

  List<DeliveryModel> get filteredDeliveries {
    if (_filter == 'All') return _all;
    return _all.where((d) => d.status == _filter).toList();
  }

  // Get new orders that need acceptance
  List<DeliveryModel> get newOrders {
    return _all.where((d) => d.status == 'New').toList();
  }

  int get totalCount => _all.length;
  int get newCount => _all.where((d) => d.status == 'New').length;
  int get pendingCount => _repo.getPendingDeliveries().length;
  int get completedCount => _repo.getCompletedDeliveries().length;
  int get cancelledCount => _repo.getCancelledDeliveries().length;

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
      amount: list[index].amount,
      time: list[index].time,
      status: newStatus,
    );
    notifyListeners();
  }

  // Accept Order using DeliveryService
  Future<bool> acceptOrder(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final deliveryPartnerId = _authController?.user?.id ?? '';

      if (deliveryPartnerId.isEmpty) {
        _isLoading = false;
        _errorMessage = 'User not authenticated';
        notifyListeners();
        return false;
      }

      // Call delivery service
      final result = await DeliveryService.acceptOrder(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
      );

      _isLoading = false;

      if (result['success'] == true) {
        // Update local status from 'New' to 'Pending'
        _updateStatus(orderId, 'Pending');
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to accept order';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error accepting order: $e';
      notifyListeners();
      return false;
    }
  }

  // Reject Order using DeliveryService
  Future<bool> rejectOrder(String orderId, {String? reason}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final deliveryPartnerId = _authController?.user?.id ?? '';

      if (deliveryPartnerId.isEmpty) {
        _isLoading = false;
        _errorMessage = 'User not authenticated';
        notifyListeners();
        return false;
      }

      final result = await DeliveryService.rejectOrder(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
        reason: reason,
      );

      _isLoading = false;

      if (result['success'] == true) {
        // Update local status to 'Rejected' or remove from list
        _updateStatus(orderId, 'Rejected');
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to reject order';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error rejecting order: $e';
      notifyListeners();
      return false;
    }
  }

  // Fetch new orders from server
  Future<void> fetchNewOrders() async {
    try {
      final deliveryPartnerId = _authController?.user?.id ?? '';
      if (deliveryPartnerId.isEmpty) return;

      final result = await DeliveryService.getNewOrders(
        deliveryPartnerId: deliveryPartnerId,
      );

      if (result['success'] == true) {
        // Process and add new orders to repository
        debugPrint('✅ Fetched ${result['count']} new orders');
        // You can update your repository here with the fetched orders
      }
    } catch (e) {
      debugPrint('❌ Error fetching new orders: $e');
    }
  }

  void markCompleted(String id) => _updateStatus(id, 'Completed');
  void markCancelled(String id) => _updateStatus(id, 'Cancelled');

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
