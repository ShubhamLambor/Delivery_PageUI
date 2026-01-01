class DeliveryModel {
  final String id;
  final String customerName;
  final String address;
  final double latitude;
  final double longitude;
  final String eta;
  final String item;
  final String status;

  DeliveryModel({
    required this.id,
    required this.customerName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.eta,
    required this.item,
    required this.status,
  });
}
