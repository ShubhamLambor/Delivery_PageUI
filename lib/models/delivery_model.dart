// lib/models/delivery_model.dart

class DeliveryModel {
  final String id;
  final String? customerId; // ✅ ADDED
  final String orderId;
  final String customerName;
  final String? customerPhone;
  final String item;
  final String address;
  final String? deliveryAddress;

  // Customer Coordinates
  final double? latitude;
  final double? longitude;

  // Pickup (Mess) Coordinates
  final double? pickupLatitude;
  final double? pickupLongitude;

  final String eta;
  final String amount;
  final String? totalAmount;
  final String time;

  /// orders.status (accepted, confirmed, ready, out_for_delivery, delivered, ...)
  final String status;

  /// delivery_assignments.status (assigned, accepted, at_pickup_location, picked_up, in_transit, ...)
  final String assignmentStatus;

  final String? messName;
  final String? messAddress;
  final String? messPhone;
  final String? paymentMethod;

  // Distance fields
  final String distBoyToMess;
  final String distMessToCust;
  final String totalDistance;

  DeliveryModel({
    required this.id,
    this.customerId, // ✅ ADDED
    String? orderId,
    required this.customerName,
    this.customerPhone,
    required this.item,
    required this.address,
    this.deliveryAddress,
    this.latitude,
    this.longitude,
    this.pickupLatitude,
    this.pickupLongitude,
    required this.eta,
    required this.amount,
    this.totalAmount,
    required this.time,
    required this.status,
    required this.assignmentStatus,
    this.messName,
    this.messAddress,
    this.messPhone,
    this.paymentMethod,
    required this.distBoyToMess,
    required this.distMessToCust,
    required this.totalDistance,
  }) : orderId = orderId ?? id;

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    final id = json['order_id']?.toString() ?? json['id']?.toString() ?? '';

    // Order status
    final rawOrderStatus = json['status']?.toString() ?? '';
    final effectiveOrderStatus =
    rawOrderStatus.isEmpty ? 'accepted' : rawOrderStatus;

    // Assignment status from delivery_assignments.status
    final rawAssignmentStatus = json['assignment_status']?.toString() ?? '';
    final normalizedAssignmentStatus =
    rawAssignmentStatus == 'at_pickup_location'
        ? 'at_pickup'
        : rawAssignmentStatus;
    final effectiveAssignmentStatus =
    normalizedAssignmentStatus.isEmpty ? 'assigned' : normalizedAssignmentStatus;

    return DeliveryModel(
      id: id,
      customerId: json['customer_id']?.toString(), // ✅ ADDED
      orderId: id,
      customerName: json['customer_name']?.toString() ?? 'Customer',
      customerPhone: json['customer_phone']?.toString(),
      item: json['mess_name']?.toString() ?? 'Food Delivery',
      address: json['delivery_address']?.toString() ??
          json['customer_address']?.toString() ??
          'Address pending',
      deliveryAddress: json['delivery_address']?.toString(),
      latitude: double.tryParse(
        json['delivery_latitude']?.toString() ??
            json['latitude']?.toString() ??
            '',
      ) ??
          null,
      longitude: double.tryParse(
        json['delivery_longitude']?.toString() ??
            json['longitude']?.toString() ??
            '',
      ) ??
          null,
      pickupLatitude:
      double.tryParse(json['pickup_latitude']?.toString() ?? ''),
      pickupLongitude:
      double.tryParse(json['pickup_longitude']?.toString() ?? ''),
      eta: json['eta']?.toString() ?? '30 mins',
      amount: json['total_amount']?.toString() ??
          json['amount']?.toString() ??
          '0',
      totalAmount: json['total_amount']?.toString() ??
          json['amount']?.toString(),
      time: json['order_time']?.toString() ??
          json['created_at']?.toString() ??
          json['time']?.toString() ??
          DateTime.now().toString(),
      status: effectiveOrderStatus,
      assignmentStatus: effectiveAssignmentStatus,
      messName: json['mess_name']?.toString(),
      messAddress: json['mess_address']?.toString(),
      messPhone: json['mess_phone']?.toString(),
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      distBoyToMess: json['dist_boy_to_mess']?.toString() ?? '0.00',
      distMessToCust: json['dist_mess_to_cust']?.toString() ?? '0.00',
      totalDistance: json['total_distance']?.toString() ?? '0.00',
    );
  }


  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Accepted';
      case 'confirmed':
        return 'Confirmed';
      case 'ready':
      case 'ready_for_pickup':
        return 'Ready';
      case 'out_for_delivery':
      case 'in_transit':
      case 'intransit':
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

  bool get isActive {
    final s = status.toLowerCase();
    return s == 'accepted' ||
        s == 'confirmed' ||
        s == 'ready' ||
        s == 'ready_for_pickup' ||
        s == 'out_for_delivery' ||
        s == 'in_transit';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'customer_id': customerId, // ✅ ADDED
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'item': item,
      'address': address,
      'delivery_address': deliveryAddress,
      'latitude': latitude,
      'longitude': longitude,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'eta': eta,
      'amount': amount,
      'total_amount': totalAmount,
      'time': time,
      'status': status,
      'assignment_status': assignmentStatus,
      'mess_name': messName,
      'mess_address': messAddress,
      'mess_phone': messPhone,
      'payment_method': paymentMethod,
      'dist_boy_to_mess': distBoyToMess,
      'dist_mess_to_cust': distMessToCust,
      'total_distance': totalDistance,
    };
  }

  DeliveryModel copyWith({
    String? id,
    String? customerId, // ✅ ADDED
    String? orderId,
    String? customerName,
    String? customerPhone,
    String? item,
    String? address,
    String? deliveryAddress,
    double? latitude,
    double? longitude,
    double? pickupLatitude,
    double? pickupLongitude,
    String? eta,
    String? amount,
    String? totalAmount,
    String? time,
    String? status,
    String? assignmentStatus,
    String? messName,
    String? messAddress,
    String? messPhone,
    String? paymentMethod,
    String? distBoyToMess,
    String? distMessToCust,
    String? totalDistance,
  }) {
    return DeliveryModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId, // ✅ ADDED
      orderId: orderId ?? this.orderId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      item: item ?? this.item,
      address: address ?? this.address,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      eta: eta ?? this.eta,
      amount: amount ?? this.amount,
      totalAmount: totalAmount ?? this.totalAmount,
      time: time ?? this.time,
      status: status ?? this.status,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
      messName: messName ?? this.messName,
      messAddress: messAddress ?? this.messAddress,
      messPhone: messPhone ?? this.messPhone,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      distBoyToMess: distBoyToMess ?? this.distBoyToMess,
      distMessToCust: distMessToCust ?? this.distMessToCust,
      totalDistance: totalDistance ?? this.totalDistance,
    );
  }

  String get deliveryAddressOrDefault => deliveryAddress ?? address;
  String get totalAmountOrDefault => totalAmount ?? amount;
  String get messNameOrDefault => messName ?? item;

  double get distBoyToMessKm => double.tryParse(distBoyToMess) ?? 0.0;
  double get distMessToCustKm => double.tryParse(distMessToCust) ?? 0.0;
  double get totalDistanceKm => double.tryParse(totalDistance) ?? 0.0;

  String get formattedDistBoyToMess =>
      '${distBoyToMessKm.toStringAsFixed(1)} km';
  String get formattedDistMessToCust =>
      '${distMessToCustKm.toStringAsFixed(1)} km';
  String get formattedTotalDistance =>
      '${totalDistanceKm.toStringAsFixed(1)} km';

  bool get hasDistanceData =>
      distBoyToMessKm > 0 || distMessToCustKm > 0 || totalDistanceKm > 0;

  double get estimatedEarnings {
    const baseRate = 10.0;
    const perKmRate = 8.0;
    return baseRate + (totalDistanceKm * perKmRate);
  }

  String get formattedEstimatedEarnings =>
      '₹${estimatedEarnings.toStringAsFixed(2)}';

  String get distanceBreakdown =>
      'To Mess: $formattedDistBoyToMess | Mess to Customer: $formattedDistMessToCust | Total: $formattedTotalDistance';

  @override
  String toString() {
    return 'DeliveryModel(id: $id, orderId: $orderId, customer: $customerName, status: $status, assignmentStatus: $assignmentStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryModel && other.id == id && other.orderId == orderId;
  }

  @override
  int get hashCode => id.hashCode ^ orderId.hashCode;
}