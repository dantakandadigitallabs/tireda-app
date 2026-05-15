class LocationSuggestion {
  final String displayName;
  final double lat;
  final double lon;

  LocationSuggestion({
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    String displayName = json['display_name'] ?? '';
    List<String> parts = displayName.split(',').map((e) => e.trim()).toList();

    // Remove unwanted parts
    // parts.removeWhere((p) =>
    // p.length <= 1 ||
    //     RegExp(r'^\d+$').hasMatch(p) ||
    //     RegExp(
    //         r'\b(World|Asia|Europe|State|District|Region|Republic|Province|Country|Postcode|Post Code)\b',
    //         caseSensitive: false)
    //         .hasMatch(p));
    //
    // if (parts.length > 5) parts = parts.take(5).toList();
    displayName = parts.join(', ');

    return LocationSuggestion(
      displayName: displayName.isNotEmpty ? displayName : json['display_name'] ?? 'Unknown Location',
      lat: double.tryParse(json['lat'] ?? '0') ?? 0.0,
      lon: double.tryParse(json['lon'] ?? '0') ?? 0.0,
    );
  }
}
