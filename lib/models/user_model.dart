// lib/models/user_model.dart
class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String profilePic;
  final String role;
  final String? vehicleNumber;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profilePic,
    this.role = 'delivery_partner', // ✅ Changed from 'customer' to 'delivery_partner'
    this.vehicleNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? "",
      email: json['email'] ?? "",
      phone: json['phone'] ?? "",
      profilePic: json['profilePic'] ?? json['profile_pic'] ?? "",
      role: json['role'] ?? 'delivery_partner', // ✅ Changed default
    );
  }

  // -----------------------------
  // UserModel → JSON (for API)
  // -----------------------------
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "phone": phone,
      "profilePic": profilePic,
      "role": role,
    };
  }

  // -----------------------------
  // copyWith() for local updates
  // -----------------------------
  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? profilePic,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePic: profilePic ?? this.profilePic,
      role: role ?? this.role,
    );
  }
}
