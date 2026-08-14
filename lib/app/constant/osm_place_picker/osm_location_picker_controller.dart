// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/osm_place_picker/location_suggestion_model.dart';
import 'package:eSellify/app/constant/osm_place_picker/osm_selected_location_model.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/utils/permissions/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class OsmLocationPickerController extends GetxController {
  RxList<LocationSuggestion> suggestions = <LocationSuggestion>[].obs;
  final MapController mapController = MapController();
  RxList<LatLng> route = <LatLng>[].obs;
  var currentLocation = Rxn<LatLng>();
  var destination = Rxn<LatLng>();
  var selectedLocation = Rxn<LatLng>();
  var selectedPlaceAddress = Rxn<Placemark>();
  RxString address = ''.obs;
  RxBool isLoading = true.obs;
  StreamSubscription<Position>? positionStream;
  final locationController = TextEditingController();
  RxString selectedAddress = ''.obs;
  TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  final int debounceDurationMs = 300;

  RxString packageName = "".obs;

  @override
  void onInit() {
    super.onInit();

    getCurrentLocation();
  }

  Future<void> getPackageInfo() async {
    packageName.value = await Constant.getPackageName();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    locationController.dispose();
    super.onClose();
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(Duration(milliseconds: debounceDurationMs), () {
      // Only call the network function if the user has paused typing
      fetchLocationSuggestions(query);
    });
  }

  Future<void> fetchLocationSuggestions(String query) async {
    suggestions.clear();
    query = query.trim();

    // Ensures a query of at least 2 characters is made
    if (query.isEmpty || query.length < 2) return;

    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=10&dedupe=1');

    try {
      final response = await http.get(url, headers: {'User-Agent': 'FlutterOSMApp/1.0 (example@app.com)'});

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final List<LocationSuggestion> cleaned = data.map<LocationSuggestion>((item) => LocationSuggestion.fromJson(item)).where((item) => item.displayName.length > 3).toList();

        // Remove duplicates (using the improved case-insensitive logic)
        final Set<String> uniqueDisplayNames = <String>{};
        final uniqueList = <LocationSuggestion>[];

        for (var item in cleaned) {
          final lowerCaseDisplayName = item.displayName.toLowerCase();
          if (uniqueDisplayNames.add(lowerCaseDisplayName)) {
            uniqueList.add(item);
          }
        }

        suggestions.value = uniqueList;
      }
      log('Suggestions: $suggestions');
    } catch (e) {
      debugPrint("Error fetching suggestions: $e");
    }
  }

  void selectSuggestion(LocationSuggestion suggestion) {
    selectedLocation.value = LatLng(suggestion.lat, suggestion.lon);
    locationController.text = suggestion.displayName;
    getAddressFromLatLng(selectedLocation.value!); // Assuming this function exists
    mapController.move(selectedLocation.value!, 16);
    suggestions.clear(); // Hide suggestions immediately
  }

  Future<void> getCurrentLocation() async {
    isLoading.value = true;
    try {
      final granted = await PermissionService.requestLocation();
      if (!granted) {
        address.value = "Location permission denied. Search or move the map to select a location.".tr;
        return;
      }

      await getPackageInfo();
      Position position = await Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: LocationAccuracy.high));

      currentLocation.value = LatLng(position.latitude, position.longitude);
      log("Current location: ${currentLocation.value}");

      // Move map after frame is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (selectedLocation.value != null) {
          mapController.move(selectedLocation.value!, 16);
        }
      });

      // Get proper address
      await getAddressFromLatLng(currentLocation.value!);
      log("current Address: ${address.value}");
    } catch (e) {
      log("Error getCurrentLocation: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        selectedPlaceAddress.value = place;
        address.value = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      }
      log('Address: ${address.value}');
    } catch (e) {
      log("Error getAddressFromLatLng: $e");
    }
  }

  void onMapMoved(LatLng center) {
    selectedLocation.value = center;
    getAddressFromLatLng(center); // Assuming this function exists
    // Clear search box and suggestions when map is manually moved
    suggestions.clear();
    locationController.text = '';
  }

  Future<void> confirmLocation() async {
    ShowToastDialog.showLoader("Please Wait..".tr);
    final LatLng? point = selectedLocation.value ?? currentLocation.value;
    if (point == null) {
      debugPrint("No location selected");
      ShowToastDialog.closeLoader();
      Get.back(result: null);
      return;
    }

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        selectedPlaceAddress.value = place;

        address.value = [place.street, place.subLocality, place.locality, place.administrativeArea, place.country].where((e) => e != null && e.isNotEmpty).join(', ');

        OsmSelectedLocationModel model = OsmSelectedLocationModel(address: place, latLng: point);

        log("Latitude: ${point.latitude}");
        log("Longitude: ${point.longitude}");
        log("Address: ${address.value}");
        log("Model: ${model.toJson()}");

        Get.back(result: model);
        ShowToastDialog.closeLoader();
      } else {
        address.value = "Address not found";
        ShowToastDialog.closeLoader();
        Get.back(result: null);
      }

      log('Address on confirm: ${address.value}');
    } catch (e) {
      debugPrint("Error confirming location: $e");
      address.value = "Unable to fetch address";
      ShowToastDialog.closeLoader();
      Get.back(result: null);
    }
  }

  Future<void> fetchCoordinatesPoints(String location) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$location&format=json&limit=1');

    try {
      final response = await http.get(url, headers: {'User-Agent': 'FlutterOSMApp/1.0 (myemail@example.com)'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          destination.value = LatLng(lat, lon);
          selectedLocation.value = destination.value;
          mapController.move(destination.value!, 16);

          // Draw route if current location exists
          if (currentLocation.value != null) getRoute(currentLocation.value!, destination.value!);
        } else {
          Get.snackbar("Not Found".tr, "Location not found".tr);
        }
      }
    } catch (e) {
      Get.snackbar("Error".tr, "$e");
    }
  }

  Future<void> getRoute(LatLng start, LatLng end) async {
    final url = Uri.parse('http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coords = data['routes'][0]['geometry']['coordinates'] as List;
        route.value = coords.map((c) => LatLng(c[1], c[0])).toList();
      }
    } catch (e) {
      debugPrint("Error fetching route: $e");
    }
  }

  void resetMap() async {
    // Clear search text
    locationController.clear();
    // suggestions.clear();
    selectedLocation.value = null;

    if (currentLocation.value != null) {
      selectedLocation.value = currentLocation.value;
      mapController.move(currentLocation.value!, 16);
      getAddressFromLatLng(currentLocation.value!);
    }
  }
}
