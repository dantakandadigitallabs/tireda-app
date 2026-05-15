// ignore_for_file: must_be_immutable, depend_on_referenced_packages, deprecated_member_use

import 'package:eSellify/app/constant/round_shape_button.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/modules/login_screen/views/login_screen_view.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/screen_size.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_field_widget.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constant/show_toast.dart';

import '../controllers/signup_screen_controller.dart';

class SignupScreenView extends GetView<SignupScreenController> {
  const SignupScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return GetBuilder(
      init: SignupScreenController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: UiInterface.customAppBar(context, themeChange, "", backgroundColor: Colors.transparent),
          body: Form(
            key: controller.formKey.value,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiInterface.joinAppWidget(),
                    spaceH(height: 16),
                    buildTopWidget(context),
                    spaceH(height: 24),
                    buildEmailPasswordWidget(context),
                    spaceH(height: 20),
                    RoundShapeButton(
                      title: "Sign Up".tr,
                      buttonColor: AppThemeData.primary4,
                      buttonTextColor: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                      onTap: () async {
                        if (controller.formKey.value.currentState!.validate()) {
                          if (controller.loginType.value == Constant.emailLoginType) {
                            if (controller.passwordController.value.text == controller.confirmPasswordController.value.text) {
                              await controller.signUp();
                            } else {
                              ShowToastDialog.showWarning("Please enter valid password".tr);
                            }
                          } else {
                            controller.saveData();
                          }
                        } else {
                          ShowToastDialog.showWarning("Please fill in all required fields.".tr);
                        }
                      },
                      size: Size(358, ScreenSize.height(7, context)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    text: "Already have an account? ".tr,
                    style: TextStyle(fontSize: 14, color: isDark ? AppThemeData.grey5 : AppThemeData.grey6, fontFamily: FontFamily.regular),
                    children: [
                      TextSpan(
                        text: "Log in".tr,
                        style: TextStyle(fontSize: 14, color: AppThemeData.secondary4, fontFamily: FontFamily.regular, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()..onTap = () => Get.to(LoginScreenView()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildTopWidget(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextCustom(title: "Create Your Account".tr, fontSize: 24, fontFamily: FontFamily.bold, color: isDark ? AppThemeData.grey1 : AppThemeData.grey10),
        spaceH(height: 4),
        TextCustom(
          title: "Create your account to join marketplace.".tr,
          fontSize: 14,
          fontFamily: FontFamily.regular,
          color: isDark ? AppThemeData.grey6 : AppThemeData.grey5,
          maxLine: 2,
        ),
      ],
    );
  }

  Widget buildEmailPasswordWidget(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.isDarkTheme();

    return Column(
      children: [
        TextFieldWidget(
          title: "First Name".tr,
          hintText: "Enter your first name".tr,
          validator: (value) => value != null && value.isNotEmpty ? null : "This field required".tr,
          controller: controller.firstNameController.value,
          onPress: () {},
        ),
        spaceH(height: 16),
        TextFieldWidget(
          title: "Last Name".tr,
          hintText: "Enter your last name".tr,
          validator: (value) => value != null && value.isNotEmpty ? null : "This field required".tr,
          controller: controller.lastNameController.value,
          onPress: () {},
        ),
        spaceH(height: 16),
        MobileNumberTextField(
          controller: controller.mobileNumberController.value,
          countryCode: controller.countryCode.value!,
          onPress: () {},
          onCountryCodeChanged: (code) {
            controller.countryCode.value = code;
          },
          title: "Mobile Number".tr,
          readOnly: controller.userModel.value.loginType == Constant.phoneLoginType,
        ),
        spaceH(height: 16),
        Obx(
          () => TextFieldWidget(
            title: "Email".tr,
            hintText: "Enter your email address".tr,
            validator: (value) => Constant.validateEmail(value),
            controller: controller.emailController.value,
            onPress: () {},
            readOnly: (controller.userModel.value.loginType == Constant.googleLoginType || controller.userModel.value.loginType == Constant.appleLoginType),
          ),
        ),
        if (controller.loginType.value == Constant.emailLoginType) ...[
          spaceH(height: 16),
          Obx(
            () => TextFieldWidget(
              title: "Password".tr,
              hintText: "Enter your password".tr,
              validator: (value) => Constant.validatePassword(value),
              controller: controller.passwordController.value,
              obscureText: controller.isPasswordVisible.value,
              suffix: GestureDetector(
                onTap: () {
                  controller.isPasswordVisible.value = !controller.isPasswordVisible.value;
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(
                    controller.isPasswordVisible.value ? "assets/icons/ic_hide_password.svg" : "assets/icons/ic_show_password.svg",
                    color: isDark ? AppThemeData.grey5 : AppThemeData.grey7,
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
              onPress: () {},
            ),
          ),
          spaceH(height: 16),
          Obx(
            () => TextFieldWidget(
              title: "Confirm Password".tr,
              hintText: "Confirm your password".tr,
              validator: (value) => Constant.validatePassword(value),
              controller: controller.confirmPasswordController.value,
              obscureText: controller.isPasswordVisible.value,
              suffix: GestureDetector(
                onTap: () {
                  controller.isPasswordVisible.value = !controller.isPasswordVisible.value;
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(
                    controller.isPasswordVisible.value ? "assets/icons/ic_hide_password.svg" : "assets/icons/ic_show_password.svg",
                    color: isDark ? AppThemeData.grey5 : AppThemeData.grey7,
                    width: 22,
                    height: 22,
                  ),
                ),
              ),
              onPress: () {},
            ),
          ),
        ],
      ],
    );
  }
}
