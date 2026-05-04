import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/driver_model.dart';
import '../../../../providers/driver_provider.dart';

// Custom dark map style for Xoho brand
const _xohoMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0d0d14"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#263c3f"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#6b9a76"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1a1a2c"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212a37"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#1f1f35"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1f2835"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f3d19c"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f3948"}]},
  {"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263c"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]},
  {"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#17263c"}]}
]
''';

class XohoMapWidget extends ConsumerStatefulWidget {
  const XohoMapWidget({
    super.key,
    this.onDriverTap,
    this.pickupLatLng,
    this.deliveryLatLng,
  });

  final void Function(DriverModel driver)? onDriverTap;
  final LatLng? pickupLatLng;
  final LatLng? deliveryLatLng;

  @override
  ConsumerState<XohoMapWidget> createState() => _XohoMapWidgetState();
}

class _XohoMapWidgetState extends ConsumerState<XohoMapWidget> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    controller.setMapStyle(_xohoMapStyle);
    _buildDriverMarkers();
  }

  void _buildDriverMarkers() {
    final drivers = ref.read(nearbyDriversProvider);
    final markers = <Marker>{};

    for (final driver in drivers) {
      markers.add(Marker(
        markerId: MarkerId(driver.id),
        position: driver.location,
        onTap: () => widget.onDriverTap?.call(driver),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          driver.mode == DriverMode.available
              ? BitmapDescriptor.hueOrange
              : BitmapDescriptor.hueYellow,
        ),
        infoWindow: InfoWindow(
          title: driver.fullName,
          snippet: '${driver.vehicleLabel} · ${driver.rating}★',
        ),
      ));
    }

    if (widget.pickupLatLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: widget.pickupLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Départ'),
      ));
    }

    if (widget.deliveryLatLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('delivery'),
        position: widget.deliveryLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Destination'),
      ));

      if (widget.pickupLatLng != null) {
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: [widget.pickupLatLng!, widget.deliveryLatLng!],
          color: AppColors.primary,
          width: 4,
          patterns: [PatternItem.dash(16), PatternItem.gap(8)],
        ));
      }
    }

    if (mounted) setState(() => _markers
      ..clear()
      ..addAll(markers));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(nearbyDriversProvider, (_, __) => _buildDriverMarkers());

    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: const CameraPosition(
        target: LatLng(
          AppConstants.defaultLat,
          AppConstants.defaultLng,
        ),
        zoom: AppConstants.defaultZoom,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      padding: const EdgeInsets.only(bottom: 140),
    );
  }
}
