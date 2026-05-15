import 'dart:convert';
import 'dart:developer' as developer;

import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/models/add_address_model.dart';
import 'package:eSellify/app/models/location_lat_lng.dart';
import 'package:eSellify/app/modules/dashboard_screen/views/dashboard_screen_view.dart';
import 'package:eSellify/app/routes/app_pages.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/preferences.dart';
import 'package:eSellify/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';

import 'package:eSellify/app/constant/show_toast.dart';

class EnterLocationController extends GetxController {
  Rx<TextEditingController> addressController = TextEditingController().obs;
  Rx<AddAddressModel> addAddressModel = AddAddressModel().obs;

  Future<void> getUserLocation() async {
    Constant.checkPermission(() async {
      ShowToastDialog.showLoader("Please Wait...".tr);

      try {
        final position = await Utils.getCurrentLocation();

        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

        if (placemarks.isEmpty) {
          throw Exception("No address found for current location".tr);
        }

        final placeMark = placemarks.first;

        final fullAddress =
            "${placeMark.name ?? ''}, ${placeMark.subLocality ?? ''}, "
            "${placeMark.locality ?? ''}, ${placeMark.administrativeArea ?? ''}, "
            "${placeMark.postalCode ?? ''}, ${placeMark.country ?? ''}";

        addressController.value.text = fullAddress;

        addAddressModel.value = AddAddressModel(
          id: Constant.getUuid(),
          address: fullAddress,
          landmark: placeMark.subLocality ?? '',
          locality: placeMark.locality ?? '',
          addressAs: "Home",
          isDefault: true,
          name: Constant.userModel?.fullNameString() ?? '',
          location: LocationLatLng(latitude: position.latitude, longitude: position.longitude),
        );

        // 🔹 Update global constant
        Constant.currentLocation.value = addAddressModel.value;

        developer.log("📍 Current location set: ${Constant.currentLocation.value!.toJson()}");

        // 🔹 Save address if user logged in
        if (await FireStoreUtils.isLogin()) {
          await saveAddress();
        } else {
          Preferences.setString(Preferences.selectedAddressKey, jsonEncode(addAddressModel.value.toJson()));
        }

        ShowToastDialog.closeLoader();
        Get.toNamed(Routes.DASHBOARD_SCREEN);
      } catch (e, stackTrace) {
        developer.log("❌ Error in getUserLocation", error: e, stackTrace: stackTrace);

        Constant.currentLocation.value = AddAddressModel(location: LocationLatLng(latitude: 19.228825, longitude: 72.854118));

        ShowToastDialog.closeLoader();
        Get.offAll(const DashboardScreenView());
      }
    });
  }

  Future<void> saveAddress() async {
    try {
      Constant.userModel!.addAddresses ??= [];
      Constant.userModel!.addAddresses!.add(addAddressModel.value);

      final result = await FireStoreUtils.updateUser(Constant.userModel!);

      ShowToastDialog.closeLoader();

      if (result == true) {
        Constant.userModel = await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()!);
      } else {
        ShowToastDialog.showError("Failed to save address. Please try again.".tr);
      }
    } catch (e, stackTrace) {
      developer.log("Error in saveAddress: $e", stackTrace: stackTrace);
    }
  }
}
