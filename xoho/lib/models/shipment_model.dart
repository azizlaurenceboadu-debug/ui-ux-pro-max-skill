import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum ShipmentStatus {
  pending,
  accepted,
  pickedUp,
  inTransit,
  delivered,
  cancelled,
  disputed,
}

enum ShipmentType { urban, interurban }

enum InsuranceType { none, basic, premium }

@immutable
class ShipmentModel {
  const ShipmentModel({
    required this.id,
    required this.senderId,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.pickupLatLng,
    required this.deliveryLatLng,
    required this.description,
    required this.proposedPriceFcfa,
    this.driverId,
    this.status = ShipmentStatus.pending,
    this.type = ShipmentType.urban,
    this.insurance = InsuranceType.none,
    this.isContactUnlocked = false,
    this.qrCode,
    this.photoUrl,
    this.weight,
    this.distanceKm,
    this.estimatedMinutes,
    this.createdAt,
    this.acceptedAt,
    this.deliveredAt,
    this.rating,
    this.review,
  });

  final String id;
  final String senderId;
  final String? driverId;
  final String pickupAddress;
  final String deliveryAddress;
  final LatLng pickupLatLng;
  final LatLng deliveryLatLng;
  final String description;
  final int proposedPriceFcfa;
  final ShipmentStatus status;
  final ShipmentType type;
  final InsuranceType insurance;
  final bool isContactUnlocked;
  final String? qrCode;
  final String? photoUrl;
  final double? weight;
  final double? distanceKm;
  final int? estimatedMinutes;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;
  final double? rating;
  final String? review;

  bool get isActive => [
        ShipmentStatus.accepted,
        ShipmentStatus.pickedUp,
        ShipmentStatus.inTransit,
      ].contains(status);

  String get statusLabel => switch (status) {
        ShipmentStatus.pending => 'En attente',
        ShipmentStatus.accepted => 'Accepté',
        ShipmentStatus.pickedUp => 'Pris en charge',
        ShipmentStatus.inTransit => 'En route',
        ShipmentStatus.delivered => 'Livré',
        ShipmentStatus.cancelled => 'Annulé',
        ShipmentStatus.disputed => 'Litige',
      };

  ShipmentModel copyWith({
    String? driverId,
    ShipmentStatus? status,
    bool? isContactUnlocked,
    String? qrCode,
    DateTime? acceptedAt,
    DateTime? deliveredAt,
    double? rating,
    String? review,
  }) {
    return ShipmentModel(
      id: id,
      senderId: senderId,
      driverId: driverId ?? this.driverId,
      pickupAddress: pickupAddress,
      deliveryAddress: deliveryAddress,
      pickupLatLng: pickupLatLng,
      deliveryLatLng: deliveryLatLng,
      description: description,
      proposedPriceFcfa: proposedPriceFcfa,
      status: status ?? this.status,
      type: type,
      insurance: insurance,
      isContactUnlocked: isContactUnlocked ?? this.isContactUnlocked,
      qrCode: qrCode ?? this.qrCode,
      photoUrl: photoUrl,
      weight: weight,
      distanceKm: distanceKm,
      estimatedMinutes: estimatedMinutes,
      createdAt: createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      rating: rating ?? this.rating,
      review: review ?? this.review,
    );
  }
}
