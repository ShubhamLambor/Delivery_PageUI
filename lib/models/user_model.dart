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
    this.role = 'delivery',  // ✅ Changed from 'delivery_partner'
    this.vehicleNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // ✅ Parse role directly without normalization
    String parsedRole = json['role']?.toString() ?? 'delivery';

    return UserModel(
      id: json['uid']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? "",
      email: json['email'] ?? "",
      phone: json['phone'] ?? "",
      profilePic: json['profilePic'] ?? json['profile_pic'] ?? "",
      role: parsedRole,
      vehicleNumber: json['vehicle_number']?.toString(),
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
      if (vehicleNumber != null) "vehicleNumber": vehicleNumber,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profilePic,
    String? role,
    String? vehicleNumber,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePic: profilePic ?? this.profilePic,
      role: role ?? this.role,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
    );
  }

  // ✅ Helper method to check if user is a delivery partner
  bool get isDeliveryPartner {
    return role == 'delivery';  // ✅ Only checks for 'delivery'
  }

  // ✅ Helper method to check if user is a customer
  bool get isCustomer {
    return role == 'customer';
  }

  // ✅ Helper method to check if user is an admin
  bool get isAdmin {
    return role == 'admin';
  }

  // ✅ Display-friendly role name
  String get displayRole {
    switch (role) {
      case 'delivery':  // ✅ Changed from 'delivery_partner'
        return 'Delivery Partner';
      case 'customer':
        return 'Customer';
      case 'admin':
        return 'Admin';
      default:
        return role;
    }
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, phone: $phone, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.profilePic == profilePic &&
        other.role == role &&
        other.vehicleNumber == vehicleNumber;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    name.hashCode ^
    email.hashCode ^
    phone.hashCode ^
    profilePic.hashCode ^
    role.hashCode ^
    vehicleNumber.hashCode;
  }
}
