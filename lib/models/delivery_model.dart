// lib/models/delivery_model.dart

class DeliveryModel {
  final String id;
  final String customerName;
  final String address;

  // Existing location fields
  final double latitude;
  final double longitude;
  final String eta;
  final String item;

  final String status; // 'Pending', 'Completed', 'Cancelled'

  // NEW FIELDS added for UI compatibility
  final double amount;
  final String time;

  DeliveryModel({
    required this.id,
    required this.customerName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.eta,
    required this.item,
    required this.status,
    this.amount = 0.0, // Default to 0.0
    this.time = '',    // Default to empty string
  });
}
