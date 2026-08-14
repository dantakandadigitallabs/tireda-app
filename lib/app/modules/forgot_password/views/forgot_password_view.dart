import 'package:eSellify/app/constant/round_shape_button.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/routes/app_pages.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/screen_size.dart';
import 'package:eSellify/widgets/text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:provider/provider.dart';
import '../controllers/forgot_password_controller.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetBuilder<ForgotPasswordController>(
      init: ForgotPasswordController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: UiInterface.customAppBar(context, themeChange, "", backgroundColor: Colors.transparent),
          body: SingleChildScrollView(
            padding: paddingEdgeInsets(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitleTextCustom(title: "Forgot Password".tr, fontSize: 24, color: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10, fontFamily: FontFamily.bold),
                spaceH(height: 8),
                TextCustom(
                  title: "Enter your email address and we'll send you a link to reset your password.".tr,
                  fontFamily: FontFamily.regular,
                  fontSize: 16,
                  color: themeChange.isDarkTheme() ? AppThemeData.grey6 : AppThemeData.grey5,
                  maxLine: 2,
                ),
                spaceH(height: 40),

                Obx(
                  () => controller.isEmailSent.value
                      ? Container(
                          padding: paddingEdgeInsets(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppThemeData.success50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppThemeData.success200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: AppThemeData.success300, size: 24),
                              spaceW(width: 12),
                              Expanded(
                                child: TextCustom(title: "Password reset email sent! Check your inbox.".tr, fontSize: 14, color: AppThemeData.success500),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(),
                ),

                spaceH(height: controller.isEmailSent.value ? 24 : 0),
                TextFieldWidget(
                  title: "Email Address",
                  validator: (value) => Constant.validateEmail(value),
                  hintText: "Enter your email address".tr,
                  controller: controller.resetEmailController.value,
                  suffix: Icon(Icons.email_outlined, color: AppThemeData.grey6, size: 20),
                  onPress: () {},
                ),

                spaceH(height: 32),

                RoundShapeButton(
                  title: "Send Link",
                  buttonColor: AppThemeData.primary4,
                  buttonTextColor: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                  onTap: () async {
                    controller.resetPassword();
                  },
                  size: Size(358, ScreenSize.height(7, context)),
                ),

                spaceH(height: 24),

                Center(
                  child: GestureDetector(
                    onTap: () {
                      Get.offAllNamed(Routes.LOGIN_SCREEN);
                    },
                    child: TextCustom(title: "Back to Login".tr, fontSize: 16, color: AppThemeData.primary4, fontFamily: FontFamily.medium, isUnderLine: true),
                  ),
                ),

                spaceH(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
