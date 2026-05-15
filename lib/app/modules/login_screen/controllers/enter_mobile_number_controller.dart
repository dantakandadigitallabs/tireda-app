import 'dart:async';
import 'dart:developer' as developer;

import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/modules/login_screen/views/verify_otp_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EnterMobileNumberController extends GetxController {
  Rx<GlobalKey<FormState>> formKey = GlobalKey<FormState>().obs;

  Rx<TextEditingController> mobileNumberController = TextEditingController().obs;
  RxBool isMobileNumberButtonEnabled = false.obs;
  Rx<String?> countryCode = Constant.countryCode.obs;
  Rx<String> verificationId = "".obs;

  RxInt secondsRemaining = 20.obs;
  RxBool enableResend = false.obs;
  Timer? timer;

  void checkFieldsFilled() {
    try {
      isMobileNumberButtonEnabled.value = mobileNumberController.value.text.isNotEmpty;
    } catch (e, stackTrace) {
      developer.log("Error in checkFieldsFilled: $e", stackTrace: stackTrace);
    }
  }

  Future<void> sendCode() async {
    try {
      ShowToastDialog.showLoader("Please Wait..".tr);

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: countryCode.value! + mobileNumberController.value.text,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          ShowToastDialog.closeLoader();

          if (e.code == 'invalid-phone-number') {
            ShowToastDialog.showError("Invalid phone number entered.".tr);
          } else if (e.code == 'too-many-requests') {
            ShowToastDialog.showWarning("Too many requests. Please try again later.".tr);
          } else {
            ShowToastDialog.showError("Verification failed: ${e.message}".tr);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          ShowToastDialog.closeLoader();
          this.verificationId.value = verificationId;
          Get.to(() => VerifyOtpView(), arguments: {"verificationId": verificationId, "countryCode": countryCode.value, "phoneNumber": mobileNumberController.value.text});
          startTimer();
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e, stackTrace) {
      ShowToastDialog.closeLoader();
      developer.log("Error in sendCode: $e", stackTrace: stackTrace);
    }
  }

  void startTimer() {
    try {
      enableResend.value = false;
      secondsRemaining.value = 20;

      timer?.cancel();

      timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        try {
          if (secondsRemaining.value > 0) {
            secondsRemaining.value--;
          } else {
            enableResend.value = true;
            timer.cancel();
          }
        } catch (e, stackTrace) {
          developer.log("Error in timer callback: $e", stackTrace: stackTrace);
          timer.cancel();
        }
      });
    } catch (e, stackTrace) {
      developer.log("Error in startTimer: $e", stackTrace: stackTrace);
    }
  }
}
