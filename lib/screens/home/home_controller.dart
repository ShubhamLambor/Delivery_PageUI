// lib/screens/home/home_controller.dart
import 'package:flutter/material.dart';
import '../../data/repository/delivery_repository.dart';
import '../../data/repository/user_repository.dart';
import '../../models/delivery_model.dart';
import '../../services/api_service.dart';

class HomeController extends ChangeNotifier {
  final DeliveryRepository deliveryRepo = DeliveryRepository();
  final UserRepository userRepo = UserRepository();

  bool _isOnline = true;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get userName => userRepo.getUser().name;

  List<DeliveryModel> get allDeliveries => deliveryRepo.getAllDeliveries();
  int get totalCount => allDeliveries.length;
  int get pendingCount => deliveryRepo.getPendingDeliveries().length;
  int get completedCount => deliveryRepo.getCompletedDeliveries().length;
  int get cancelledCount => deliveryRepo.getCancelledDeliveries().length;

  DeliveryModel? get currentDelivery {
    final list = deliveryRepo.getPendingDeliveries();
    return list.isNotEmpty ? list.first : null;
  }

  List<DeliveryModel> get upcomingDeliveries =>
      deliveryRepo.getPendingDeliveries();

  /// Toggle online/offline status with backend call
  Future<void> toggleOnline() async {
    if (_isLoading) return; // Prevent multiple simultaneous requests

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final newStatus = !_isOnline;

    final result = await ApiService.updatePartnerStatus(
      partnerId: _getPartnerId(),
      isOnline: newStatus,
      partnerName: userName,
    );

    if (result['success'] == true || result['status'] == 'success') {
      _isOnline = newStatus;
      debugPrint('✅ Status updated: ${_isOnline ? "Online" : "Offline"}');
    } else {
      _errorMessage = result['message'] ?? 'Failed to update status';
      debugPrint('⚠️ Error: $_errorMessage');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch current status from backend (call on app start)
  Future<void> fetchOnlineStatus() async {
    try {
      final result = await ApiService.getPartnerStatus(
        partnerId: _getPartnerId(),
      );

      if (result['success'] == true) {
        _isOnline = result['status'] == '1' ||
            result['status'] == 'online' ||
            result['is_online'] == true;
        notifyListeners();
        debugPrint('✅ Fetched status: ${_isOnline ? "Online" : "Offline"}');
      }
    } catch (e) {
      debugPrint('Error fetching status: $e');
    }
  }

  /// Get partner ID from user repository
  String _getPartnerId() {
    final user = userRepo.getUser();
    // Adjust based on your User model structure
    return user.id ?? user.phone ?? 'unknown';
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
