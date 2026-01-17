// lib/data/repository/dummy_data.dart

import '../../models/delivery_model.dart';
import '../../models/earning_model.dart';
import '../../models/user_model.dart';

class DummyData {
  // ✅ REMOVED: No longer using dummy deliveries
  static List<DeliveryModel> deliveries = [];

  // Keep earnings empty or for testing only
  static List<EarningModel> earnings = [];

  // Default user model (can keep for initial profile display)
  static UserModel user = UserModel(
    id: '',
    name: "Delivery Partner",
    email: "delivery@example.com",
    phone: "9876543210",
    profilePic: "https://cdn-icons-png.flaticon.com/512/3177/3177440.png",
    role: "delivery",
  );
}
