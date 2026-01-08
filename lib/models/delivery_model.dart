// lib/models/delivery_model.dart

class DeliveryModel {
  final String id;
  final String customerName;
  final String item;
  final String address;
  final double? latitude;
  final double? longitude;
  final String eta;
  final String amount;
  final String time;
  final String status;

  DeliveryModel({
    required this.id,
    required this.customerName,
    required this.item,
    required this.address,
    this.latitude,
    this.longitude,
    required this.eta,
    required this.amount,
    required this.time,
    required this.status,
  });

  /// ✅ NEW: Parse from backend JSON (URL-encoded response)
  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryModel(
      id: json['order_id']?.toString() ?? json['id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'Customer',
      item: json['mess_name']?.toString() ?? 'Food Delivery',
      address: json['delivery_address']?.toString() ??
          json['customer_address']?.toString() ??
          'Address pending',
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      eta: json['eta']?.toString() ?? '30 mins',
      amount: json['total_amount']?.toString() ??
          json['amount']?.toString() ?? '0',
      time: json['order_time']?.toString() ??
          json['time']?.toString() ??
          DateTime.now().toString(),
      status: _parseStatus(json['assignment_status']?.toString() ??
          json['status']?.toString() ?? 'assigned'),
    );
  }

  /// Map backend status to app status
  static String _parseStatus(String backendStatus) {
    switch (backendStatus.toLowerCase()) {
      case 'assigned':
        return 'New';
      case 'accepted':
        return 'Pending';
      case 'picked_up':
      case 'pickedup':
      case 'in_transit':
      case 'intransit':
        return 'Pending';
      case 'delivered':
      case 'completed':
        return 'Completed';
      case 'rejected':
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'New';
    }
  }

  /// ✅ NEW: Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_name': customerName,
      'item': item,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'eta': eta,
      'amount': amount,
      'time': time,
      'status': status,
    };
  }

  /// ✅ NEW: Copy with method
  DeliveryModel copyWith({
    String? id,
    String? customerName,
    String? item,
    String? address,
    double? latitude,
    double? longitude,
    String? eta,
    String? amount,
    String? time,
    String? status,
  }) {
    return DeliveryModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      item: item ?? this.item,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      eta: eta ?? this.eta,
      amount: amount ?? this.amount,
      time: time ?? this.time,
      status: status ?? this.status,
    );
  }
}
