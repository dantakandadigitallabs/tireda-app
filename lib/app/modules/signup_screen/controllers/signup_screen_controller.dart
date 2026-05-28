// ignore_for_file: invalid_return_type_for_catch_error, depend_on_referenced_packages

import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/extension/string_extensions.dart';
import 'package:eSellify/app/models/add_address_model.dart';
import 'package:eSellify/app/models/user_model.dart';
import 'package:eSellify/app/modules/signup_screen/views/enter_location_view.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/app/services/email_template_service.dart';
import 'package:eSellify/utils/notifications/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eSellify/app/constant/show_toast.dart';

class SignupScreenController extends GetxController {
  Rx<GlobalKey<FormState>> formKey = GlobalKey<FormState>().obs;

  Rx<UserModel> userModel = UserModel().obs;

  Rx<TextEditingController> firstNameController = TextEditingController().obs;
  Rx<TextEditingController> lastNameController = TextEditingController().obs;
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> mobileNumberController = TextEditingController().obs;
  Rx<TextEditingController> passwordController = TextEditingController().obs;
  Rx<TextEditingController> confirmPasswordController = TextEditingController().obs;
  Rx<TextEditingController> addressController = TextEditingController().obs;
  Rx<TextEditingController> referralCodeController = TextEditingController().obs;
  Rx<String?> countryCode = Constant.countryCode.obs;
  RxBool isPasswordVisible = true.obs;
  RxString loginType = "".obs;

  Rx<AddAddressModel> addAddressModel = AddAddressModel().obs;

  @override
  void onInit() {
    getArgument();
    super.onInit();
  }

  Future<void> getArgument() async {
    try {
      dynamic argumentData = Get.arguments;
      if (argumentData != null) {
        if (argumentData['type'] != null) {
          loginType.value = argumentData['type'];
        } else if (argumentData['userModel'] != null) {
          userModel.value = await argumentData['userModel'];
          loginType.value = userModel.value.loginType!;
        }
        if (loginType.value == Constant.phoneLoginType) {
          mobileNumberController.value.text = userModel.value.phoneNumber.toString();
          countryCode.value = userModel.value.countryCode.toString();
        } else if (loginType.value == Constant.googleLoginType || loginType.value == Constant.appleLoginType) {
          emailController.value.text = userModel.value.email.toString();
          if (userModel.value.firstName != null && userModel.value.firstName!.isNotEmpty) {
            firstNameController.value.text = userModel.value.firstName!;
          }
          if (userModel.value.lastName != null && userModel.value.lastName!.isNotEmpty) {
            lastNameController.value.text = userModel.value.lastName!;
          }
          countryCode.value = Constant.countryCode;
        }
      }
      update();
    } catch (e, stack) {
      developer.log("Error getting arguments: $e", stackTrace: stack);
    }
  }

  Future<UserCredential?> signUpEmailWithPass(String email, String password) async {
    return await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> saveData() async {
    ShowToastDialog.showLoader("Please Wait..".tr);
    try {
      userModel.value.firstName = firstNameController.value.text;
      userModel.value.lastName = lastNameController.value.text;
      userModel.value.slug = Constant.fullNameString(firstNameController.value.text, lastNameController.value.text).toSlug(delimiter: "-");
      userModel.value.email = emailController.value.text;
      userModel.value.countryCode = countryCode.value;
      userModel.value.phoneNumber = mobileNumberController.value.text;
      userModel.value.profilePic = '';
      userModel.value.createdAt = Timestamp.now();
      userModel.value.isActive = true;
      userModel.value.userType = Constant.user;
      userModel.value.searchEmailKeywords = Constant.generateKeywords(emailController.value.text);
      userModel.value.searchNameKeywords = Constant.generateKeywords(userModel.value.fullNameString());

      bool? success = await FireStoreUtils.addUser(userModel.value);
      if (success == true) {
        Constant.userModel = await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()!);

        await EmailTemplateService.sendEmail(
          type: 'welcome',
          toEmail: userModel.value.email!,
          variables: {'name': userModel.value.fullNameString(), 'email': userModel.value.email ?? '', 'app_name': Constant.appName.toString()},
        );
        // ✅ Use Get.offAll with widget instead of named route
        ShowToastDialog.closeLoader();
        Get.offAll(() => EnterLocationView(isRedirectDashboard: true));
      } else {
        ShowToastDialog.showError("Failed to save user data.".tr);
      }
    } catch (e, stack) {
      developer.log("Error saving data: $e", stackTrace: stack);
    } finally {
      ShowToastDialog.closeLoader();
    }
  }

  Future<void> signUp() async {
    String email = emailController.value.text;
    String password = passwordController.value.text;

    ShowToastDialog.showLoader("Please Wait..".tr);

    try {
      final value = await signUpEmailWithPass(email, password);

      if (value?.user?.uid == null) {
        throw Exception("User ID is null".tr);
      }
      String fcmToken = await NotificationService.getToken();

      userModel.value.id = value!.user!.uid;
      userModel.value.firstName = firstNameController.value.text;
      userModel.value.lastName = lastNameController.value.text;
      userModel.value.slug = Constant.fullNameString(firstNameController.value.text, lastNameController.value.text).toSlug(delimiter: "-");
      userModel.value.loginType = Constant.emailLoginType;
      userModel.value.email = email;
      userModel.value.countryCode = countryCode.value;
      userModel.value.phoneNumber = mobileNumberController.value.text;
      userModel.value.profilePic = '';
      userModel.value.fcmToken = fcmToken;
      userModel.value.createdAt = Timestamp.now();
      userModel.value.isActive = true;
      userModel.value.userType = Constant.user;
      userModel.value.searchEmailKeywords = Constant.generateKeywords(emailController.value.text);
      userModel.value.searchNameKeywords = Constant.generateKeywords(userModel.value.fullNameString());

      bool? updated = await FireStoreUtils.updateUser(userModel.value);

      if (updated == true) {
        developer.log("============> 77777777");
        await EmailTemplateService.sendEmail(
          type: 'welcome',
          toEmail: userModel.value.email!,
          variables: {'name': userModel.value.fullNameString(), 'email': userModel.value.email ?? '', 'app_name': Constant.appName.toString()},
        );

        ShowToastDialog.closeLoader();
        Get.offAll(() => EnterLocationView(isRedirectDashboard: true));
      } else {
        ShowToastDialog.showError("Failed to update user data.".tr);
      }
    } on FirebaseAuthException catch (e) {
      developer.log("FirebaseAuthException during sign up: ${e.code}");
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = "This email is already in use.".tr;
          break;
        case 'invalid-email':
          message = "The email address is not valid.".tr;
          break;
        case 'weak-password':
          message = "The password is too weak.".tr;
          break;
        default:
          message = "Authentication error: ${e.message}";
      }
      ShowToastDialog.showError(message);
    } finally {
      ShowToastDialog.closeLoader();
    }
  }
}
