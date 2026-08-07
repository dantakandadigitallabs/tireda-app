// ignore_for_file: depend_on_referenced_packages

import 'dart:developer' as developer;

import 'package:eSellify/utils/permissions/permission_service.dart';
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

      final granted = await PermissionService.requestLocation();
      if (!granted) {
        throw 'Location permissions are denied';
      }

      return await Geolocator.getCurrentPosition();
    } catch (e,stack) {
      developer.log("Error getting current location: ", error: e, stackTrace: stack);
      rethrow;
    }
  }

}