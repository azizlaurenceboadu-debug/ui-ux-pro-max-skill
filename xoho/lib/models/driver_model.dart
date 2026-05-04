import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum DriverMode { available, busy, offline }

enum VehicleType { motorcycle, car, tricycle, truck, foot }

@immutable
class DriverModel {
  const DriverModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.location,
    this.avatarUrl,
    this.vehicleType = VehicleType.motorcycle,
    this.mode = DriverMode.offline,
    this.rating = 5.0,
    this.totalDeliveries = 0,
    this.isVerified = false,
    this.plannedTrips = const [],
  });

  final String id;
  final String fullName;
  final String phone;
  final LatLng location;
  final String? avatarUrl;
  final VehicleType vehicleType;
  final DriverMode mode;
  final double rating;
  final int totalDeliveries;
  final bool isVerified;
  final List<PlannedTrip> plannedTrips;

  String get vehicleLabel => switch (vehicleType) {
        VehicleType.motorcycle => 'Moto',
        VehicleType.car => 'Voiture',
        VehicleType.tricycle => 'Tricycle',
        VehicleType.truck => 'Camion',
        VehicleType.foot => 'À pied',
      };

  String get vehicleEmoji => switch (vehicleType) {
        VehicleType.motorcycle => '🏍',
        VehicleType.car => '🚗',
        VehicleType.tricycle => '🛺',
        VehicleType.truck => '🚚',
        VehicleType.foot => '🚶',
      };

  DriverModel copyWith({
    LatLng? location,
    DriverMode? mode,
    double? rating,
    int? totalDeliveries,
    List<PlannedTrip>? plannedTrips,
  }) {
    return DriverModel(
      id: id,
      fullName: fullName,
      phone: phone,
      location: location ?? this.location,
      avatarUrl: avatarUrl,
      vehicleType: vehicleType,
      mode: mode ?? this.mode,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      isVerified: isVerified,
      plannedTrips: plannedTrips ?? this.plannedTrips,
    );
  }
}

@immutable
class PlannedTrip {
  const PlannedTrip({
    required this.id,
    required this.driverId,
    required this.originCity,
    required this.destinationCity,
    required this.departureTime,
    this.availableCapacityKg = 20.0,
    this.maxPackages = 5,
    this.pricePerKg = 100,
  });

  final String id;
  final String driverId;
  final String originCity;
  final String destinationCity;
  final DateTime departureTime;
  final double availableCapacityKg;
  final int maxPackages;
  final int pricePerKg;
}
