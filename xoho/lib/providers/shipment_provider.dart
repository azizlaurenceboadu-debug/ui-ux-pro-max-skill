import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/shipment_model.dart';

const _uuid = Uuid();

final shipmentProvider =
    StateNotifierProvider<ShipmentNotifier, ShipmentState>((ref) {
  return ShipmentNotifier();
});

final activeShipmentProvider = Provider<ShipmentModel?>((ref) {
  final state = ref.watch(shipmentProvider);
  return state.shipments.where((s) => s.isActive).firstOrNull;
});

class ShipmentState {
  const ShipmentState({
    this.shipments = const [],
    this.isLoading = false,
    this.error,
  });

  final List<ShipmentModel> shipments;
  final bool isLoading;
  final String? error;

  ShipmentState copyWith({
    List<ShipmentModel>? shipments,
    bool? isLoading,
    String? error,
  }) {
    return ShipmentState(
      shipments: shipments ?? this.shipments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ShipmentNotifier extends StateNotifier<ShipmentState> {
  ShipmentNotifier() : super(const ShipmentState()) {
    _loadDemoData();
  }

  void _loadDemoData() {
    state = state.copyWith(shipments: [
      ShipmentModel(
        id: 'shp_001',
        senderId: 'usr_demo',
        pickupAddress: 'Quartier Cadjehoun, Cotonou',
        deliveryAddress: 'Marché Dantokpa, Cotonou',
        pickupLatLng: const LatLng(6.3654, 2.4183),
        deliveryLatLng: const LatLng(6.3550, 2.4280),
        description: 'Colis de vêtements (5kg) – fragile',
        proposedPriceFcfa: 800,
        status: ShipmentStatus.pending,
        type: ShipmentType.urban,
        insurance: InsuranceType.basic,
        distanceKm: 3.5,
        estimatedMinutes: 20,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      ShipmentModel(
        id: 'shp_002',
        senderId: 'usr_demo',
        pickupAddress: 'Cotonou, Gare routière',
        deliveryAddress: 'Parakou, Centre-ville',
        pickupLatLng: const LatLng(6.3620, 2.4210),
        deliveryLatLng: const LatLng(9.3370, 2.6289),
        description: 'Pièces électroniques (2kg)',
        proposedPriceFcfa: 3500,
        status: ShipmentStatus.inTransit,
        type: ShipmentType.interurban,
        insurance: InsuranceType.premium,
        driverId: 'drv_001',
        distanceKm: 412,
        estimatedMinutes: 360,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        acceptedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
      ),
    ]);
  }

  Future<ShipmentModel> createShipment({
    required String senderId,
    required String pickupAddress,
    required String deliveryAddress,
    required LatLng pickupLatLng,
    required LatLng deliveryLatLng,
    required String description,
    required int proposedPriceFcfa,
    ShipmentType type = ShipmentType.urban,
    InsuranceType insurance = InsuranceType.none,
    double? weight,
  }) async {
    state = state.copyWith(isLoading: true);

    final shipment = ShipmentModel(
      id: 'shp_${_uuid.v4().substring(0, 8)}',
      senderId: senderId,
      pickupAddress: pickupAddress,
      deliveryAddress: deliveryAddress,
      pickupLatLng: pickupLatLng,
      deliveryLatLng: deliveryLatLng,
      description: description,
      proposedPriceFcfa: proposedPriceFcfa,
      type: type,
      insurance: insurance,
      weight: weight,
      qrCode: _uuid.v4(),
      createdAt: DateTime.now(),
    );

    // TODO: save to Firestore
    await Future.delayed(const Duration(milliseconds: 800));

    state = state.copyWith(
      shipments: [...state.shipments, shipment],
      isLoading: false,
    );

    return shipment;
  }

  Future<void> unlockDriver(String shipmentId) async {
    // TODO: trigger Cloud Function to deduct 100 FCFA and reveal contact
    final updated = state.shipments.map((s) {
      if (s.id == shipmentId) return s.copyWith(isContactUnlocked: true);
      return s;
    }).toList();
    state = state.copyWith(shipments: updated);
  }

  Future<void> updateStatus(String shipmentId, ShipmentStatus status) async {
    final updated = state.shipments.map((s) {
      if (s.id == shipmentId) return s.copyWith(status: status);
      return s;
    }).toList();
    state = state.copyWith(shipments: updated);
  }

  Future<void> confirmDelivery(
      String shipmentId, double rating, String review) async {
    final updated = state.shipments.map((s) {
      if (s.id == shipmentId) {
        return s.copyWith(
          status: ShipmentStatus.delivered,
          rating: rating,
          review: review,
          deliveredAt: DateTime.now(),
        );
      }
      return s;
    }).toList();
    state = state.copyWith(shipments: updated);
  }
}
