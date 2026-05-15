import 'dart:math';

class DistanceUtils {
  static const double _earthRadiusKm = 6371.0;
  static const double _earthRadiusMiles = 3958.8;

  /// Calculate distance between two coordinates using the Haversine formula.
  /// Returns distance in kilometers.
  static double haversineDistanceKm(double lat1, double lng1, double lat2, double lng2) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLng / 2) * sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  /// Calculate distance and return in the specified unit.
  /// [distanceType] should be "KM" or "Miles".
  static double haversineDistance(double lat1, double lng1, double lat2, double lng2, {String distanceType = "KM"}) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLng / 2) * sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final radius = distanceType == "Miles" ? _earthRadiusMiles : _earthRadiusKm;
    return radius * c;
  }

  /// Format distance for display — e.g., "2.5 km" or "0.3 km"
  static String formatDistance(double distanceKm, {String distanceType = "KM"}) {
    if (distanceType == "Miles") {
      final miles = distanceKm * 0.621371;
      if (miles < 0.1) return '< 0.1 mi';
      return '${miles.toStringAsFixed(1)} mi';
    }
    if (distanceKm < 1) return '${(distanceKm * 1000).round()} m';
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
