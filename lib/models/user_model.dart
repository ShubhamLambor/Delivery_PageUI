// lib/models/user_model.dart

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profilePic;
  final String role;
  final String? vehicleNumber;
  final bool isEmailVerified;
  final bool isPhoneVerified;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profilePic,
    this.role = 'delivery',
    this.vehicleNumber,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parse role directly without normalization
    String parsedRole = json['role']?.toString() ?? 'delivery';

    // Parse verification status (handles both int and bool from backend)
    bool emailVerified = false;
    if (json['is_email_verified'] != null) {
      emailVerified = json['is_email_verified'] == 1 ||
          json['is_email_verified'] == true ||
          json['is_email_verified'] == '1';
    }

    bool phoneVerified = false;
    if (json['is_phone_verified'] != null) {
      phoneVerified = json['is_phone_verified'] == 1 ||
          json['is_phone_verified'] == true ||
          json['is_phone_verified'] == '1';
    }

    return UserModel(
      id: json['uid']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? "",
      email: json['email'] ?? "",
      phone: json['phone'] ?? "",
      profilePic: json['profilePic'] ?? json['profile_pic'] ?? "",
      role: parsedRole,
      vehicleNumber: json['vehicle_number']?.toString(),
      isEmailVerified: emailVerified,
      isPhoneVerified: phoneVerified,
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
      "isEmailVerified": isEmailVerified,
      "isPhoneVerified": isPhoneVerified,
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
    bool? isEmailVerified,
    bool? isPhoneVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePic: profilePic ?? this.profilePic,
      role: role ?? this.role,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    );
  }

  // ✅ Helper method to check if user is a delivery partner
  bool get isDeliveryPartner {
    return role == 'delivery';
  }

  // ✅ Helper method to check if user is a customer
  bool get isCustomer {
    return role == 'customer';
  }

  // ✅ Helper method to check if user is an admin
  bool get isAdmin {
    return role == 'admin';
  }

  // ✅ Check if both email and phone are verified
  bool get isFullyVerified {
    return isEmailVerified && isPhoneVerified;
  }

  // ✅ Check if at least one contact method is verified
  bool get hasAnyVerification {
    return isEmailVerified || isPhoneVerified;
  }

  // ✅ Get verification status summary
  String get verificationStatus {
    if (isFullyVerified) {
      return 'Fully Verified';
    } else if (isEmailVerified && !isPhoneVerified) {
      return 'Email Verified';
    } else if (!isEmailVerified && isPhoneVerified) {
      return 'Phone Verified';
    } else {
      return 'Not Verified';
    }
  }

  // ✅ Display-friendly role name
  String get displayRole {
    switch (role) {
      case 'delivery':
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
    return 'UserModel(id: $id, name: $name, email: $email, phone: $phone, role: $role, emailVerified: $isEmailVerified, phoneVerified: $isPhoneVerified)';
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
        other.vehicleNumber == vehicleNumber &&
        other.isEmailVerified == isEmailVerified &&
        other.isPhoneVerified == isPhoneVerified;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    name.hashCode ^
    email.hashCode ^
    phone.hashCode ^
    profilePic.hashCode ^
    role.hashCode ^
    vehicleNumber.hashCode ^
    isEmailVerified.hashCode ^
    isPhoneVerified.hashCode;
  }
}
