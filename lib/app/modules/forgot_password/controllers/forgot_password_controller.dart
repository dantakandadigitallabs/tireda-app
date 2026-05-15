import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constant/show_toast.dart';

class ForgotPasswordController extends GetxController {
  Rx<TextEditingController> resetEmailController = TextEditingController().obs;
  RxBool isEmailSent = false.obs;

  Future<void> resetPassword() async {
    ShowToastDialog.showLoader("Please Wait..");
    String email = resetEmailController.value.text.trim();

    if (email.isEmpty || !GetUtils.isEmail(email)) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showError("Please enter a valid email");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      isEmailSent.value = true;
      ShowToastDialog.closeLoader();
      ShowToastDialog.showSuccess("Password reset email sent successfully");
    } on FirebaseAuthException catch (e) {
      String message = "Something went wrong";

      if (e.code == 'user-not-found') {
        message = "No user found with this email";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email address";
      }
      ShowToastDialog.closeLoader();
      ShowToastDialog.showError(message);
      developer.log("Firebase error: ${e.code}");
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showError("Error occurred");
      developer.log("Error in resetPassword: $e");
    } finally {
      ShowToastDialog.closeLoader();
    }
  }

  @override
  void onClose() {
    resetEmailController.value.dispose();
    super.onClose();
  }
}
