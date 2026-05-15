import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';

/// A unified map widget that shows Google Map or OSM based on Constant.selectedMap
class MapViewWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double zoom;
  final double? height;
  final double? width;
  final double borderRadius;
  final bool interactive;

  const MapViewWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.zoom = 14,
    this.height,
    this.width,
    this.borderRadius = 12,
    this.interactive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: width ?? double.infinity,
        child: Constant.selectedMap == "Google Map" ? _buildGoogleMap() : _buildOSMMap(),
      ),
    );
  }

  Widget _buildGoogleMap() {
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(latitude, longitude),
        zoom: zoom,
      ),
      markers: {
        gmaps.Marker(
          markerId: const gmaps.MarkerId('location'),
          position: gmaps.LatLng(latitude, longitude),
        ),
      },
      zoomControlsEnabled: false,
      scrollGesturesEnabled: interactive,
      zoomGesturesEnabled: interactive,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  Widget _buildOSMMap() {
    final point = LatLng(latitude, longitude);
    return AbsorbPointer(
      absorbing: !interactive,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: point,
          initialZoom: zoom,
          interactionOptions: interactive
              ? const InteractionOptions()
              : const InteractionOptions(flags: InteractiveFlag.none),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.esellify.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 28,
                height: 28,
                child: const Icon(Icons.location_pin, color: AppThemeData.danger300, size: 26),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
