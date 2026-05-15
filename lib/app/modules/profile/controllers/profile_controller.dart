import 'dart:developer' as developer;

import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';

import '../../../models/user_model.dart' show UserModel;

class ProfileController extends GetxController {
  RxBool isLoading = true.obs;
  Rx<UserModel> userModel = UserModel().obs;

  @override
  void onInit() {
    getData();
    super.onInit();
  }

  Future<void> getData() async {
    try {
      if (FireStoreUtils.getCurrentUid() != null) {
        final user = await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid().toString());
        if (user != null) {
          userModel.value = user;
        }
        update();
      }
    } catch (e, stack) {
      developer.log("Error getting user data: $e", stackTrace: stack);
    } finally {
      isLoading.value = false;
    }
  }
}
