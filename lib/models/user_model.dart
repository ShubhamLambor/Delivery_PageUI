// lib/models/user_model.dart

class UserModel {
  final String id;
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
    this.role = 'delivery',  // ✅ Changed default from 'delivery_partner' to 'delivery'
    this.vehicleNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['uid']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? "",
      email: json['email'] ?? "",
      phone: json['phone'] ?? "",
      profilePic: json['profilePic'] ?? json['profile_pic'] ?? "",
      role: json['role'] ?? 'delivery',  // ✅ Changed default from 'delivery_partner' to 'delivery'
    );
  }

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

  UserModel copyWith({
    String? id,
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
