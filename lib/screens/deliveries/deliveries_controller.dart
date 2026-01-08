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
    final delivery = getById(id);
    if (delivery == null) return;

    final updated = DeliveryModel(
      id: delivery.id,
      customerName: delivery.customerName,
      item: delivery.item,
      address: delivery.address,
      latitude: delivery.latitude,
      longitude: delivery.longitude,
      eta: delivery.eta,
      amount: delivery.amount,
      time: delivery.time,
      status: newStatus,
    );

    _repo.addOrUpdateOrder(updated);
    notifyListeners();
  }

  /// ✅ Fetch/refresh all deliveries from backend
  Future<void> fetchDeliveries() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final deliveryPartnerId = _authController?.user?.id ?? '';

      if (deliveryPartnerId.isEmpty) {
        debugPrint('⚠️ Cannot fetch deliveries: User not authenticated');
        _isLoading = false;
        _errorMessage = 'User not authenticated';
        notifyListeners();
        return;
      }

      debugPrint('🔄 Fetching deliveries for partner: $deliveryPartnerId');

      // Fetch new orders
      await fetchNewOrders();

      // Fetch active orders
      await fetchActiveOrders();

      // Fetch order history (optional)
      // await fetchOrderHistory();

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      debugPrint('✅ All deliveries fetched successfully');
      debugPrint('   Total orders: ${_repo.realDeliveryCount}');
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to fetch deliveries: $e';
      notifyListeners();
      debugPrint('❌ Error fetching deliveries: $e');
    }
  }

  /// ✅ Fetch active/ongoing orders
  Future<void> fetchActiveOrders() async {
    try {
      final deliveryPartnerId = _authController?.user?.id ?? '';
      if (deliveryPartnerId.isEmpty) return;

      debugPrint('🔄 Fetching active orders...');

      final result = await DeliveryService.getActiveOrders(
        deliveryPartnerId: deliveryPartnerId,
      );

      if (result['success'] == true) {
        final orders = result['orders'] as List? ?? [];
        debugPrint('✅ Fetched ${result['count']} active orders');

        // ✅ SAVE TO REPOSITORY
        for (var orderData in orders) {
          try {
            final delivery = DeliveryModel.fromJson(orderData);
            _repo.addOrUpdateOrder(delivery);
            debugPrint('   ➕ Added active order: ${delivery.id}');
          } catch (e) {
            debugPrint('   ⚠️ Error parsing order: $e');
          }
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error fetching active orders: $e');
    }
  }

  /// ✅ Fetch new orders from server
  Future<void> fetchNewOrders() async {
    try {
      final deliveryPartnerId = _authController?.user?.id ?? '';
      if (deliveryPartnerId.isEmpty) return;

      debugPrint('🔄 Fetching new orders...');

      final result = await DeliveryService.getNewOrders(
        deliveryPartnerId: deliveryPartnerId,
      );

      if (result['success'] == true) {
        final orders = result['orders'] as List? ?? [];
        debugPrint('✅ Fetched ${result['count']} new orders');

        // ✅ SAVE TO REPOSITORY
        for (var orderData in orders) {
          try {
            final delivery = DeliveryModel.fromJson(orderData);
            _repo.addOrUpdateOrder(delivery);
            debugPrint('   ➕ Added new order: ${delivery.id}');
          } catch (e) {
            debugPrint('   ⚠️ Error parsing order: $e');
          }
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error fetching new orders: $e');
    }
  }

  /// ✅ Fetch order history
  Future<void> fetchOrderHistory({int? limit}) async {
    try {
      final deliveryPartnerId = _authController?.user?.id ?? '';
      if (deliveryPartnerId.isEmpty) return;

      debugPrint('🔄 Fetching order history...');

      final result = await DeliveryService.getOrderHistory(
        deliveryPartnerId: deliveryPartnerId,
        limit: limit,
      );

      if (result['success'] == true) {
        final orders = result['orders'] as List? ?? [];
        debugPrint('✅ Fetched ${result['count']} historical orders');

        // ✅ SAVE TO REPOSITORY
        for (var orderData in orders) {
          try {
            final delivery = DeliveryModel.fromJson(orderData);
            _repo.addOrUpdateOrder(delivery);
          } catch (e) {
            debugPrint('   ⚠️ Error parsing history order: $e');
          }
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error fetching order history: $e');
    }
  }

  /// ✅ Fetch partner stats
  Future<Map<String, dynamic>?> fetchPartnerStats() async {
    try {
      final deliveryPartnerId = _authController?.user?.id ?? '';
      if (deliveryPartnerId.isEmpty) return null;

      debugPrint('📊 Fetching partner stats...');

      final result = await DeliveryService.getPartnerStats(
        deliveryPartnerId: deliveryPartnerId,
      );

      if (result['success'] == true) {
        debugPrint('✅ Partner stats fetched');
        return result['stats'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('❌ Error fetching partner stats: $e');
    }
    return null;
  }

  /// ✅ Refresh all data
  Future<void> refresh() async {
    debugPrint('🔄 Refreshing all delivery data...');
    await fetchDeliveries();
  }

  /// Accept Order using DeliveryService
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

      debugPrint('✅ Accepting order: $orderId');

      final result = await DeliveryService.acceptOrder(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
      );

      _isLoading = false;

      if (result['success'] == true) {
        // Update local status
        _updateStatus(orderId, 'Pending');
        _errorMessage = null;

        // Refresh deliveries after acceptance
        await fetchDeliveries();

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
      debugPrint('❌ Error accepting order: $e');
      return false;
    }
  }

  /// Reject Order using DeliveryService
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

      debugPrint('❌ Rejecting order: $orderId');

      final result = await DeliveryService.rejectOrder(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
        reason: reason,
      );

      _isLoading = false;

      if (result['success'] == true) {
        // Remove from list or update status
        _repo.removeDelivery(orderId);
        _errorMessage = null;

        // Refresh deliveries after rejection
        await fetchDeliveries();

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
      debugPrint('❌ Error rejecting order: $e');
      return false;
    }
  }

  /// ✅ Mark order as picked up
  Future<bool> markPickedUp(String orderId) async {
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

      final result = await DeliveryService.markPickedUp(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
      );

      _isLoading = false;

      if (result['success'] == true) {
        _updateStatus(orderId, 'Pending');
        await fetchDeliveries();
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to mark as picked up';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error marking as picked up: $e';
      notifyListeners();
      return false;
    }
  }

  /// ✅ Mark order as delivered
  Future<bool> markDelivered(String orderId, {String? notes}) async {
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

      final result = await DeliveryService.markDelivered(
        orderId: orderId,
        deliveryPartnerId: deliveryPartnerId,
        notes: notes,
      );

      _isLoading = false;

      if (result['success'] == true) {
        _updateStatus(orderId, 'Completed');
        await fetchDeliveries();
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to mark as delivered';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error marking as delivered: $e';
      notifyListeners();
      return false;
    }
  }

  void markCompleted(String id) => _updateStatus(id, 'Completed');
  void markCancelled(String id) => _updateStatus(id, 'Cancelled');

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// ✅ Get delivery partner ID
  String? get partnerId => _authController?.user?.id;

  /// ✅ Check if user is authenticated
  bool get isAuthenticated => partnerId != null && partnerId!.isNotEmpty;
}
