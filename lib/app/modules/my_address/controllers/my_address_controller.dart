import 'dart:developer' as developer;

import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/models/add_address_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyAddressController extends GetxController {
  RxBool isLoading = true.obs;

  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  RxList<AddAddressModel> addresses = <AddAddressModel>[].obs;
  Rx<AddAddressModel> addressModel = AddAddressModel().obs;
  Rx<AddAddressModel?> selectedAddress = Rx<AddAddressModel?>(null);
  Rx<TextEditingController> addressController = TextEditingController().obs;
  Rx<TextEditingController> locationController = TextEditingController().obs;
  RxString addressAs = 'Home'.obs;

  @override
  void onInit() {
    getData();
    super.onInit();
  }

  Future<void> getData() async {
    try {
      isLoading.value = true;

      final user = await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()!);

      if (user != null && user.addAddresses != null) {
        addresses.value = user.addAddresses!;
      } else {
        ShowToastDialog.showError("No address data found.".tr);
      }
      if (Constant.currentLocation.value != null) {
        selectedAddress.value = addresses.firstWhereOrNull((e) => e.id == Constant.currentLocation.value!.id);
      }
      selectedAddress.value ??= addresses.firstWhereOrNull((e) => e.isDefault == true) ?? (addresses.isNotEmpty ? addresses.first : null);
    } catch (e, stackTrace) {
      developer.log("Error in getData: $e", error: e, stackTrace: stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAddress(int index) async {
    try {
      final address = Constant.userModel!.addAddresses![index];

      if (address.isDefault == true) {
        ShowToastDialog.showError("Cannot delete default address.".tr);
        return;
      }

      Constant.userModel!.addAddresses!.removeAt(index);
      final result = await FireStoreUtils.updateUser(Constant.userModel!);

      if (result == true) {
        getData();
      } else {
        ShowToastDialog.showError("Failed to delete address.".tr);
      }
    } catch (e, stackTrace) {
      developer.log("Error in deleteAddress: $e", error: e, stackTrace: stackTrace);
    }
  }

  Future<void> saveAddress(AddAddressModel addressModel) async {
    isLoading.value = true;

    try {
      addressModel.id ??= Constant.getUuid();

      Constant.userModel!.addAddresses ??= [];

      // ✅ Prevent duplicate (same id)
      Constant.userModel!.addAddresses!.removeWhere((e) => e.id == addressModel.id);

      Constant.userModel!.addAddresses!.add(addressModel);

      bool? updated = await FireStoreUtils.updateUser(Constant.userModel!);

      if (updated == true) {
        Constant.userModel = await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()!);
      }

      await getData();
    } catch (e, stack) {
      developer.log('Error saving address: ', error: e, stackTrace: stack);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateAddress(String addressId, AddAddressModel addressModel) async {
    try {
      final list = Constant.userModel!.addAddresses ?? [];

      for (int i = 0; i < list.length; i++) {
        if (list[i].id == addressId) {
          final old = list[i];

          list[i] = addressModel
            ..id = addressId
            ..location = addressModel.location ?? old.location
            ..locality = addressModel.locality ?? old.locality
            ..landmark = addressModel.landmark ?? old.landmark;

          break;
        }
      }

      await FireStoreUtils.updateUser(Constant.userModel!);
      Constant.userModel = await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()!);

      await getData();
    } catch (e, stack) {
      developer.log('Error updating address: ', error: e, stackTrace: stack);
    }
  }
}
