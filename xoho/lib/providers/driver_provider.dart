import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/driver_model.dart';

final driverProvider =
    StateNotifierProvider<DriverNotifier, DriverState>((ref) {
  return DriverNotifier();
});

final nearbyDriversProvider = Provider<List<DriverModel>>((ref) {
  return ref.watch(driverProvider).nearbyDrivers;
});

class DriverState {
  const DriverState({
    this.nearbyDrivers = const [],
    this.myPlannedTrips = const [],
    this.isOnline = false,
    this.currentMode = DriverMode.offline,
    this.isLoading = false,
  });

  final List<DriverModel> nearbyDrivers;
  final List<PlannedTrip> myPlannedTrips;
  final bool isOnline;
  final DriverMode currentMode;
  final bool isLoading;

  DriverState copyWith({
    List<DriverModel>? nearbyDrivers,
    List<PlannedTrip>? myPlannedTrips,
    bool? isOnline,
    DriverMode? currentMode,
    bool? isLoading,
  }) {
    return DriverState(
      nearbyDrivers: nearbyDrivers ?? this.nearbyDrivers,
      myPlannedTrips: myPlannedTrips ?? this.myPlannedTrips,
      isOnline: isOnline ?? this.isOnline,
      currentMode: currentMode ?? this.currentMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DriverNotifier extends StateNotifier<DriverState> {
  DriverNotifier() : super(const DriverState()) {
    _loadDemoDrivers();
  }

  void _loadDemoDrivers() {
    state = state.copyWith(nearbyDrivers: [
      const DriverModel(
        id: 'drv_001',
        fullName: 'Kofi Mensah',
        phone: '+22997000001',
        location: LatLng(6.3680, 2.4200),
        vehicleType: VehicleType.motorcycle,
        mode: DriverMode.available,
        rating: 4.8,
        totalDeliveries: 234,
        isVerified: true,
      ),
      const DriverModel(
        id: 'drv_002',
        fullName: 'Aïssa Kérékou',
        phone: '+22997000002',
        location: LatLng(6.3620, 2.4150),
        vehicleType: VehicleType.car,
        mode: DriverMode.available,
        rating: 4.5,
        totalDeliveries: 98,
        isVerified: true,
      ),
      const DriverModel(
        id: 'drv_003',
        fullName: 'Sébastien Hounton',
        phone: '+22997000003',
        location: LatLng(6.3700, 2.4250),
        vehicleType: VehicleType.motorcycle,
        mode: DriverMode.busy,
        rating: 4.2,
        totalDeliveries: 57,
        isVerified: false,
      ),
      const DriverModel(
        id: 'drv_004',
        fullName: 'Marie Akpo',
        phone: '+22997000004',
        location: LatLng(6.3590, 2.4300),
        vehicleType: VehicleType.tricycle,
        mode: DriverMode.available,
        rating: 4.9,
        totalDeliveries: 312,
        isVerified: true,
      ),
    ]);
  }

  void toggleOnlineMode(bool isOnline) {
    state = state.copyWith(
      isOnline: isOnline,
      currentMode: isOnline ? DriverMode.available : DriverMode.offline,
    );
  }

  Future<PlannedTrip> registerTrip({
    required String driverId,
    required String originCity,
    required String destinationCity,
    required DateTime departureTime,
    double availableCapacityKg = 20.0,
    int maxPackages = 5,
    int pricePerKg = 100,
  }) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 600));

    final trip = PlannedTrip(
      id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      driverId: driverId,
      originCity: originCity,
      destinationCity: destinationCity,
      departureTime: departureTime,
      availableCapacityKg: availableCapacityKg,
      maxPackages: maxPackages,
      pricePerKg: pricePerKg,
    );

    state = state.copyWith(
      myPlannedTrips: [...state.myPlannedTrips, trip],
      isLoading: false,
    );

    return trip;
  }

  void updateDriverLocation(String driverId, LatLng newLocation) {
    final updated = state.nearbyDrivers.map((d) {
      if (d.id == driverId) return d.copyWith(location: newLocation);
      return d;
    }).toList();
    state = state.copyWith(nearbyDrivers: updated);
  }
}
