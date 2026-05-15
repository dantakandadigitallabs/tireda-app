import 'dart:developer';
import 'dart:io';

import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/extension/string_extensions.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constant/show_toast.dart';

class EditProfileController extends GetxController {
  Rx<bool> isLoading = false.obs;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Rx<TextEditingController> firstNameController = TextEditingController().obs;
  Rx<TextEditingController> lastNameController = TextEditingController().obs;
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> mobileController = TextEditingController().obs;
  Rx<String?> countryCode = Constant.countryCode.obs;

  RxString profileImage = "".obs;
  ImagePicker imagePicker = ImagePicker();

  @override
  void onInit() {
    getData();

    super.onInit();
  }

  void getData() {
    firstNameController.value.text = Constant.userModel!.firstName.toString();
    lastNameController.value.text = Constant.userModel!.lastName.toString();
    emailController.value.text = Constant.userModel!.email.toString();
    mobileController.value.text = Constant.userModel!.phoneNumber.toString();
    countryCode.value = Constant.userModel!.countryCode.toString();
    profileImage.value = Constant.userModel!.profilePic.toString();
  }

  Future<void> updateProfile() async {
    ShowToastDialog.showLoader("Please Wait..".tr);
    if (profileImage.value.isNotEmpty && Constant.hasValidUrl(profileImage.value) == false) {
      profileImage.value = await Constant.uploadImageToFireStorage(
        File(profileImage.value),
        "user_profile/${FireStoreUtils.getCurrentUid()}",
        File(profileImage.value).path.split('/').last,
      );
    }

    // await upLoadImageToFireStore();
    Constant.userModel!.profilePic = profileImage.value;
    Constant.userModel!.firstName = firstNameController.value.text;
    Constant.userModel!.lastName = lastNameController.value.text;
    Constant.userModel!.email = emailController.value.text;
    Constant.userModel!.countryCode = countryCode.value;
    Constant.userModel!.phoneNumber = mobileController.value.text;
    Constant.userModel!.slug = Constant.fullNameString(firstNameController.value.text, lastNameController.value.text).toSlug(delimiter: "-");
    Constant.userModel!.searchNameKeywords = Constant.generateKeywords(Constant.userModel!.fullNameString());
    Constant.userModel!.searchEmailKeywords = Constant.generateKeywords(emailController.value.text);

    final updatedUser = await FireStoreUtils.updateUser(Constant.userModel!);
    if (updatedUser) {
      firstNameController.value.clear();
      lastNameController.value.clear();
      emailController.value.clear();
      mobileController.value.clear();
      ShowToastDialog.showSuccess("Update successfully.".tr);
      Get.back(result: true);
      ShowToastDialog.closeLoader();
    } else {
      ShowToastDialog.showError("Failed to update profile.".tr);
      ShowToastDialog.closeLoader();
    }
  }

  Future<void> pickFile({required ImageSource source}) async {
    isLoading.value = true;
    try {
      XFile? image = await imagePicker.pickImage(source: source, imageQuality: 100);
      if (image == null) return;

      Get.back();

      profileImage.value = image.path;
    } catch (e) {
      log("Error picking image: $e");
    }
    isLoading.value = false;
  }
}
