// lib/models/delivery_model.dart

class DeliveryModel {
  final String id;
  final String orderId;
  final String customerName;
  final String? customerPhone;
  final String item;
  final String address;
  final String? deliveryAddress;
  final double? latitude;
  final double? longitude;
  final String eta;
  final String amount;
  final String? totalAmount;
  final String time;
  final String status;
  final String? messName;
  final String? messAddress;
  final String? messPhone;
  final String? paymentMethod;

  DeliveryModel({
    required this.id,
    String? orderId,
    required this.customerName,
    this.customerPhone,
    required this.item,
    required this.address,
    this.deliveryAddress,
    this.latitude,
    this.longitude,
    required this.eta,
    required this.amount,
    this.totalAmount,
    required this.time,
    required this.status,
    this.messName,
    this.messAddress,
    this.messPhone,
    this.paymentMethod,
  }) : orderId = orderId ?? id;

  /// ✅ Parse from backend JSON
  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    final id = json['order_id']?.toString() ?? json['id']?.toString() ?? '';

    return DeliveryModel(
      id: id,
      orderId: id,
      customerName: json['customer_name']?.toString() ?? 'Customer',
      customerPhone: json['customer_phone']?.toString(),
      item: json['mess_name']?.toString() ?? 'Food Delivery',
      address: json['delivery_address']?.toString() ??
          json['customer_address']?.toString() ??
          'Address pending',
      deliveryAddress: json['delivery_address']?.toString(),
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      eta: json['eta']?.toString() ?? '30 mins',
      amount: json['total_amount']?.toString() ??
          json['amount']?.toString() ?? '0',
      totalAmount: json['total_amount']?.toString() ?? json['amount']?.toString(),
      time: json['order_time']?.toString() ??
          json['created_at']?.toString() ??
          json['time']?.toString() ??
          DateTime.now().toString(),
      // ✅ FIXED: Keep original status from backend
      status: json['assignment_status']?.toString() ??
          json['status']?.toString() ?? 'assigned',
      messName: json['mess_name']?.toString(),
      messAddress: json['mess_address']?.toString(),
      messPhone: json['mess_phone']?.toString(),
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
    );
  }

  /// ✅ REMOVED _parseStatus - keep raw backend status

  /// ✅ Helper method to get display-friendly status for UI
  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'assigned':
      case 'pending_assignment':
        return 'New';
      case 'confirmed':
        return 'Confirmed';
      case 'accepted':
        return 'Accepted';
      case 'ready':
      case 'ready_for_pickup':
        return 'Ready';
      case 'picked_up':
      case 'pickedup':
      case 'at_pickup_location':
        return 'Picked Up';
      case 'in_transit':
      case 'intransit':
      case 'out_for_delivery':
        return 'In Transit';
      case 'delivered':
      case 'completed':
        return 'Delivered';
      case 'rejected':
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  /// ✅ Helper method to check if delivery is active
  bool get isActive {
    final s = status.toLowerCase();
    return s == 'accepted' ||
        s == 'ready' ||
        s == 'ready_for_pickup' ||
        s == 'picked_up' ||
        s == 'at_pickup_location' ||
        s == 'in_transit' ||
        s == 'out_for_delivery';
  }

  /// ✅ Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'item': item,
      'address': address,
      'delivery_address': deliveryAddress,
      'latitude': latitude,
      'longitude': longitude,
      'eta': eta,
      'amount': amount,
      'total_amount': totalAmount,
      'time': time,
      'status': status,
      'mess_name': messName,
      'mess_address': messAddress,
      'mess_phone': messPhone,
      'payment_method': paymentMethod,
    };
  }

  /// ✅ Copy with method
  DeliveryModel copyWith({
    String? id,
    String? orderId,
    String? customerName,
    String? customerPhone,
    String? item,
    String? address,
    String? deliveryAddress,
    double? latitude,
    double? longitude,
    String? eta,
    String? amount,
    String? totalAmount,
    String? time,
    String? status,
    String? messName,
    String? messAddress,
    String? messPhone,
    String? paymentMethod,
  }) {
    return DeliveryModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      item: item ?? this.item,
      address: address ?? this.address,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      eta: eta ?? this.eta,
      amount: amount ?? this.amount,
      totalAmount: totalAmount ?? this.totalAmount,
      time: time ?? this.time,
      status: status ?? this.status,
      messName: messName ?? this.messName,
      messAddress: messAddress ?? this.messAddress,
      messPhone: messPhone ?? this.messPhone,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  /// ✅ Helper getters for backward compatibility
  String get deliveryAddressOrDefault => deliveryAddress ?? address;
  String get totalAmountOrDefault => totalAmount ?? amount;
  String get messNameOrDefault => messName ?? item;
}
