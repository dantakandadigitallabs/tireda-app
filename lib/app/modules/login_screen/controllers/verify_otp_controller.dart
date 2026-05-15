
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/modules/login_screen/controllers/enter_mobile_number_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VerifyOtpController extends GetxController {
  Rx<String> otpCode = "".obs;

  Rx<TextEditingController> mobileNumberController = TextEditingController().obs;
  Rx<String?> countryCode = Constant.countryCode.obs;
  Rx<String> verificationId = "".obs;

  EnterMobileNumberController enterMobileNumberController = Get.put(EnterMobileNumberController());

  @override
  void onInit() {
    getArguments();
    super.onInit();
  }

  void getArguments() {
    dynamic arguments = Get.arguments;
    if (arguments != null) {
      verificationId.value = arguments["verificationId"];
      countryCode.value = arguments["countryCode"];
      mobileNumberController.value.text = arguments["phoneNumber"];
    }
  }
}
