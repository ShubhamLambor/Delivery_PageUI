// lib/models/delivery_model.dart

class DeliveryModel {
  final String id;
  final String orderId;
  final String customerName;
  final String? customerPhone;
  final String item;
  final String address;
  final String? deliveryAddress;

  // ✅ Customer Coordinates
  final double? latitude;
  final double? longitude;

  // ✅ ADDED: Pickup (Mess) Coordinates
  final double? pickupLatitude;
  final double? pickupLongitude;

  final String eta;
  final String amount;
  final String? totalAmount;
  final String time;
  final String status;
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
    String? orderId,
    required this.customerName,
    this.customerPhone,
    required this.item,
    required this.address,
    this.deliveryAddress,
    this.latitude,
    this.longitude,

    // ✅ Initialize new fields
    this.pickupLatitude,
    this.pickupLongitude,

    required this.eta,
    required this.amount,
    this.totalAmount,
    required this.time,
    required this.status,
    this.messName,
    this.messAddress,
    this.messPhone,
    this.paymentMethod,
    required this.distBoyToMess,
    required this.distMessToCust,
    required this.totalDistance,
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

      // ✅ Parse Customer Coordinates
      latitude: double.tryParse(json['delivery_latitude']?.toString() ?? json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['delivery_longitude']?.toString() ?? json['longitude']?.toString() ?? ''),

      // ✅ Parse Pickup Coordinates
      pickupLatitude: double.tryParse(json['pickup_latitude']?.toString() ?? ''),
      pickupLongitude: double.tryParse(json['pickup_longitude']?.toString() ?? ''),

      eta: json['eta']?.toString() ?? '30 mins',
      amount: json['total_amount']?.toString() ?? json['amount']?.toString() ?? '0',
      totalAmount: json['total_amount']?.toString() ?? json['amount']?.toString(),
      time: json['order_time']?.toString() ??
          json['created_at']?.toString() ??
          json['time']?.toString() ??
          DateTime.now().toString(),

      // ✅ FIX: Read 'status' first (order status), not 'assignment_status'
      status: json['status']?.toString() ?? 'assigned',

      messName: json['mess_name']?.toString(),
      messAddress: json['mess_address']?.toString(),
      messPhone: json['mess_phone']?.toString(),
      paymentMethod: json['payment_method']?.toString() ?? 'cash',

      // Parse distance fields
      distBoyToMess: json['dist_boy_to_mess']?.toString() ?? '0.00',
      distMessToCust: json['dist_mess_to_cust']?.toString() ?? '0.00',
      totalDistance: json['total_distance']?.toString() ?? '0.00',
    );
  }


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
      'pickup_latitude': pickupLatitude, // ✅ Added
      'pickup_longitude': pickupLongitude, // ✅ Added
      'eta': eta,
      'amount': amount,
      'total_amount': totalAmount,
      'time': time,
      'status': status,
      'mess_name': messName,
      'mess_address': messAddress,
      'mess_phone': messPhone,
      'payment_method': paymentMethod,
      'dist_boy_to_mess': distBoyToMess,
      'dist_mess_to_cust': distMessToCust,
      'total_distance': totalDistance,
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
    double? pickupLatitude, // ✅ Added
    double? pickupLongitude, // ✅ Added
    String? eta,
    String? amount,
    String? totalAmount,
    String? time,
    String? status,
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
      orderId: orderId ?? this.orderId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      item: item ?? this.item,
      address: address ?? this.address,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude, // ✅ Added
      pickupLongitude: pickupLongitude ?? this.pickupLongitude, // ✅ Added
      eta: eta ?? this.eta,
      amount: amount ?? this.amount,
      totalAmount: totalAmount ?? this.totalAmount,
      time: time ?? this.time,
      status: status ?? this.status,
      messName: messName ?? this.messName,
      messAddress: messAddress ?? this.messAddress,
      messPhone: messPhone ?? this.messPhone,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      distBoyToMess: distBoyToMess ?? this.distBoyToMess,
      distMessToCust: distMessToCust ?? this.distMessToCust,
      totalDistance: totalDistance ?? this.totalDistance,
    );
  }

  /// ✅ Helper getters for backward compatibility
  String get deliveryAddressOrDefault => deliveryAddress ?? address;
  String get totalAmountOrDefault => totalAmount ?? amount;
  String get messNameOrDefault => messName ?? item;

  /// ✅ Distance helper methods - Get distances as doubles for calculations
  double get distBoyToMessKm => double.tryParse(distBoyToMess) ?? 0.0;
  double get distMessToCustKm => double.tryParse(distMessToCust) ?? 0.0;
  double get totalDistanceKm => double.tryParse(totalDistance) ?? 0.0;

  /// ✅ Formatted distance strings for UI display
  String get formattedDistBoyToMess => '${distBoyToMessKm.toStringAsFixed(1)} km';
  String get formattedDistMessToCust => '${distMessToCustKm.toStringAsFixed(1)} km';
  String get formattedTotalDistance => '${totalDistanceKm.toStringAsFixed(1)} km';

  /// ✅ Check if distance data is available
  bool get hasDistanceData =>
      distBoyToMessKm > 0 || distMessToCustKm > 0 || totalDistanceKm > 0;

  /// ✅ Calculate estimated earnings based on distance
  double get estimatedEarnings {
    const baseRate = 10.0;
    const perKmRate = 8.0;
    return baseRate + (totalDistanceKm * perKmRate);
  }

  String get formattedEstimatedEarnings => '₹${estimatedEarnings.toStringAsFixed(2)}';

  String get distanceBreakdown =>
      'To Mess: $formattedDistBoyToMess | Mess to Customer: $formattedDistMessToCust | Total: $formattedTotalDistance';

  @override
  String toString() {
    return 'DeliveryModel(id: $id, orderId: $orderId, customer: $customerName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryModel && other.id == id && other.orderId == orderId;
  }

  @override
  int get hashCode => id.hashCode ^ orderId.hashCode;
}