// ignore_for_file: deprecated_member_use, must_be_immutable, depend_on_referenced_packages

import 'package:eSellify/app/constant/round_shape_button.dart';
import 'package:eSellify/app/modules/login_screen/controllers/enter_mobile_number_controller.dart';
import 'package:eSellify/app/modules/login_screen/views/login_screen_view.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/screen_size.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../../../widgets/text_field_widget.dart';

class EnterMobileNumberScreenView extends GetView<EnterMobileNumberController> {
  const EnterMobileNumberScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetBuilder(
      init: EnterMobileNumberController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: UiInterface.customAppBar(context, themeChange, "", backgroundColor: Colors.transparent),
          body: Form(
            key: controller.formKey.value,
            child: SingleChildScrollView(
              child: Padding(
                padding: paddingEdgeInsets(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiInterface.joinAppWidget(),
                    spaceH(height: 16),
                    buildTopWidget(context),
                    spaceH(height: 28),
                    buildMobileNumberWidget(context),
                    spaceH(height: 52),
                    Row(
                      children: [
                        Expanded(
                          child: RoundShapeButton(
                            title: "Get OTP".tr,
                            buttonColor: AppThemeData.primary4,
                            buttonTextColor: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                            onTap: () {
                              if (controller.formKey.value.currentState!.validate()) {
                                controller.sendCode();
                              }
                            },
                            size: Size(358, ScreenSize.height(7, context)),
                          ),
                        ),
                      ],
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
                    style: TextStyle(fontSize: 14, color: themeChange.isDarkTheme() ? AppThemeData.grey5 : AppThemeData.grey6, fontFamily: FontFamily.regular),
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

  SizedBox buildTopWidget(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextCustom(title: "Sign In to Your Account", fontSize: 24, fontFamily: FontFamily.bold, color: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10),
          spaceH(height: 4),
          TextCustom(
            title: "Enter your phone number to continue buying and selling.",
            fontSize: 14,
            fontFamily: FontFamily.regular,
            color: themeChange.isDarkTheme() ? AppThemeData.grey6 : AppThemeData.grey5,
            maxLine: 2,
          ),
        ],
      ),
    );
  }

  MobileNumberTextField buildMobileNumberWidget(BuildContext context) {
    return MobileNumberTextField(
      controller: controller.mobileNumberController.value,
      countryCode: controller.countryCode.value!,
      onCountryCodeChanged: (code) {
        controller.countryCode.value = code;
      },
      onPress: () {},
      title: "Mobile Number".tr,
    );
  }
}
