import 'dart:io';

import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/round_shape_button.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/utils/screen_size.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/network_image_widget.dart';
import 'package:eSellify/widgets/text_field_widget.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../controllers/edit_profile_controller.dart';

class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetBuilder(
      init: EditProfileController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: UiInterface.customAppBar(context, themeChange, "Edit Profile".tr),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: controller.formKey,
                    child: Padding(
                      padding: paddingEdgeInsets(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    height: 86,
                                    width: 86,
                                    decoration: BoxDecoration(shape: BoxShape.circle),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: controller.isLoading.value
                                          ? Constant.loader(context: context)
                                          : controller.profileImage.isEmpty
                                          ? Image.asset(Constant.userPlaceHolder, height: 56, width: 56, fit: BoxFit.cover)
                                          : (Constant.hasValidUrl(controller.profileImage.value))
                                          ? NetworkImageWidget(imageUrl: controller.profileImage.value, height: 56, width: 56, borderRadius: 0, fit: BoxFit.cover)
                                          : Image.file(File(controller.profileImage.value), height: 56, width: 56, fit: BoxFit.cover),
                                    ),
                                  ),

                                  GestureDetector(
                                    onTap: () {
                                      buildBottomSheet(context, controller, themeChange);
                                    },
                                    child: Container(
                                      height: 30,
                                      width: 30,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: themeChange.isDarkTheme() ? AppThemeData.grey9 : AppThemeData.grey2,
                                        border: Border.all(color: AppThemeData.primary4),
                                      ),
                                      child: Padding(padding: const EdgeInsets.all(5.0), child: SvgPicture.asset("assets/icons/ic_camera.svg")),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          spaceH(height: 16),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                            decoration: BoxDecoration(
                              color: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                TextFieldWidget(
                                  title: "First Name",
                                  hintText: "Enter First Name".tr,
                                  controller: controller.firstNameController.value,
                                  validator: (value) => value != null && value.isNotEmpty ? null : "First Name is Required.",
                                  onPress: () {},
                                ),
                                spaceH(height: 20),
                                TextFieldWidget(
                                  title: "Last Name",
                                  hintText: "Enter Last Name".tr,
                                  controller: controller.lastNameController.value,
                                  validator: (value) => value != null && value.isNotEmpty ? null : "Last Name is Required.",
                                  onPress: () {},
                                ),
                                spaceH(height: 20),
                                TextFieldWidget(
                                  title: "Email",
                                  hintText: "Enter Email".tr,
                                  controller: controller.emailController.value,
                                  validator: (value) => value != null && value.isNotEmpty ? null : "Email is Required.",
                                  readOnly: Constant.userModel!.loginType != Constant.phoneLoginType ? true : false,
                                  onPress: () {},
                                ),
                                spaceH(height: 20),
                                MobileNumberTextField(
                                  controller: controller.mobileController.value,
                                  countryCode: controller.countryCode.toString(),
                                  onCountryCodeChanged: (code) {
                                    controller.countryCode.value = code;
                                  },
                                  readOnly: Constant.userModel!.loginType == Constant.phoneLoginType ? true : false,
                                  onPress: () {},
                                  title: "Mobile Number",
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
                      child: RoundShapeButton(
                        title: "Update Profile".tr,
                        buttonColor: AppThemeData.primary4,
                        buttonTextColor: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                        onTap: () {
                          if (controller.formKey.currentState!.validate()) {
                            controller.updateProfile();
                          }
                        },
                        size: Size(0, ScreenSize.height(7, context)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

Future buildBottomSheet(BuildContext context, EditProfileController controller, DarkThemeProvider themeChange) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return SizedBox(
            height: ScreenSize.height(25, context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: paddingEdgeInsets(),
                  child: TextCustom(title: "Please Select".tr, fontSize: 18, fontFamily: FontFamily.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: paddingEdgeInsets(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () => controller.pickFile(source: ImageSource.camera),
                            icon: Icon(Icons.camera_alt, size: 32, color: AppThemeData.primary4),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: TextCustom(title: "Camera".tr),
                          ),
                        ],
                      ),
                    ),
                    spaceW(width: 36),
                    Padding(
                      padding: paddingEdgeInsets(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () => controller.pickFile(source: ImageSource.gallery),
                            icon: Icon(Icons.photo, size: 32, color: AppThemeData.primary4),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: TextCustom(title: "Gallery".tr),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
