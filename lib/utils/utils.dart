// ignore_for_file: depend_on_referenced_packages

import 'dart:developer' as developer;

import 'package:geolocator/geolocator.dart';


class Utils {
  static Future<Position> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      while (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        await Future.delayed(const Duration(seconds: 2)); // wait briefly before rechecking
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
      }

      return await Geolocator.getCurrentPosition();
    } catch (e,stack) {
      developer.log("Error getting current location: ", error: e, stackTrace: stack);
      rethrow;
    }
  }

}
