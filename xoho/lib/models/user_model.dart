import 'package:flutter/foundation.dart';

enum UserRole { sender, driver, both }

enum KycStatus { none, pending, verified, rejected }

@immutable
class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.avatarUrl,
    this.role = UserRole.sender,
    this.kycStatus = KycStatus.none,
    this.rating = 5.0,
    this.totalDeliveries = 0,
    this.walletBalance = 0,
    this.isOnline = false,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final UserRole role;
  final KycStatus kycStatus;
  final double rating;
  final int totalDeliveries;
  final int walletBalance;
  final bool isOnline;
  final DateTime? createdAt;

  bool get isVerified => kycStatus == KycStatus.verified;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'X';
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? avatarUrl,
    UserRole? role,
    KycStatus? kycStatus,
    double? rating,
    int? totalDeliveries,
    int? walletBalance,
    bool? isOnline,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      kycStatus: kycStatus ?? this.kycStatus,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      walletBalance: walletBalance ?? this.walletBalance,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'avatarUrl': avatarUrl,
        'role': role.name,
        'kycStatus': kycStatus.name,
        'rating': rating,
        'totalDeliveries': totalDeliveries,
        'walletBalance': walletBalance,
        'isOnline': isOnline,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        role: UserRole.values.byName(json['role'] ?? 'sender'),
        kycStatus: KycStatus.values.byName(json['kycStatus'] ?? 'none'),
        rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
        totalDeliveries: json['totalDeliveries'] as int? ?? 0,
        walletBalance: json['walletBalance'] as int? ?? 0,
        isOnline: json['isOnline'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );
}
