import 'package:eSellify/app/constant/round_shape_button.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/modules/forgot_password/views/forgot_password_view.dart';
import 'package:eSellify/app/modules/login_screen/views/enter_mobile_number_view.dart';
import 'package:eSellify/app/modules/signup_screen/views/signup_screen_view.dart';
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
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/login_screen_controller.dart';

class LoginScreenView extends GetView<LoginScreenController> {
  const LoginScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetBuilder(
      init: LoginScreenController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: UiInterface.customAppBar(context, themeChange, "", backgroundColor: Colors.transparent, isBack: false),
          body: Form(
            key: controller.formKey.value,
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UiInterface.joinAppWidget(),
                        spaceH(height: 16),
                        buildTopWidget(context),
                        spaceH(height: 24),
                        buildEmailPasswordWidget(context),
                        spaceH(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: GestureDetector(
                                onTap: () {
                                  Get.to(ForgotPasswordView());
                                },
                                child: TextCustom(
                                  title: "Forgot password?".tr,
                                  fontSize: 14,
                                  color: AppThemeData.primary4,
                                  fontFamily: FontFamily.regular,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                          ],
                        ),
                        spaceH(height: 40),
                        Row(
                          children: [
                            Expanded(
                              child: RoundShapeButton(
                                title: "Log in".tr,
                                buttonColor: AppThemeData.primary4,
                                buttonTextColor: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                                onTap: () {
                                  if (controller.formKey.value.currentState!.validate()) {
                                    controller.emailSignIn();
                                  } else {
                                    ShowToastDialog.showWarning("Please enter valid information.".tr);
                                  }
                                },
                                size: Size(0, ScreenSize.height(7, context)),
                              ),
                            ),
                          ],
                        ),
                        spaceH(height: 12),
                        Row(
                          children: [
                            Expanded(child: Divider(color: themeChange.isDarkTheme() ? AppThemeData.grey8 : AppThemeData.grey3)),
                            spaceW(),
                            Text(
                              "Or".tr,
                              style: TextStyle(fontSize: 14, fontFamily: FontFamily.regular, color: themeChange.isDarkTheme() ? AppThemeData.grey6 : AppThemeData.grey5),
                              textAlign: TextAlign.right,
                            ),
                            spaceW(),
                            Expanded(child: Divider(color: themeChange.isDarkTheme() ? AppThemeData.grey8 : AppThemeData.grey3)),
                          ],
                        ),
                        spaceH(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: RoundShapeButton(
                                titleWidget: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset("assets/icons/ic_google.svg"),
                                    spaceW(width: 12),
                                    Text(
                                      "Google".tr,
                                      style: TextStyle(fontFamily: FontFamily.regular, fontSize: 16, color: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10),
                                    ),
                                  ],
                                ),
                                buttonColor: themeChange.isDarkTheme() ? AppThemeData.grey9 : AppThemeData.grey2,
                                buttonTextColor: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10,
                                onTap: () {
                                  controller.loginWithGoogle();
                                },
                                size: Size(0, ScreenSize.height(7, context)),
                                title: '',
                              ),
                            ),
                            spaceW(width: 16),
                            Expanded(
                              child: RoundShapeButton(
                                titleWidget: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      "assets/icons/ic_apple.svg",
                                      colorFilter: ColorFilter.mode(themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10, BlendMode.srcIn),
                                    ),
                                    spaceW(width: 12),
                                    Text(
                                      "Apple".tr,
                                      style: TextStyle(fontFamily: FontFamily.regular, fontSize: 16, color: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10),
                                    ),
                                  ],
                                ),
                                buttonColor: themeChange.isDarkTheme() ? AppThemeData.grey9 : AppThemeData.grey2,
                                buttonTextColor: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10,
                                onTap: () {
                                  controller.loginWithApple();
                                },
                                size: Size(0, ScreenSize.height(7, context)),
                                title: '',
                              ),
                            ),
                          ],
                        ),
                        spaceH(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: RoundShapeButton(
                                titleWidget: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,

                                  children: [
                                    SvgPicture.asset(
                                      "assets/icons/ic_phone.svg",
                                      colorFilter: ColorFilter.mode(themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10, BlendMode.srcIn),
                                    ),
                                    spaceW(width: 12),
                                    Text(
                                      "Continue with mobile number".tr,
                                      style: TextStyle(fontFamily: FontFamily.regular, color: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10, fontSize: 16),
                                    ),
                                  ],
                                ),
                                buttonColor: themeChange.isDarkTheme() ? AppThemeData.grey9 : AppThemeData.grey2,
                                buttonTextColor: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10,
                                onTap: () {
                                  Get.to(() => EnterMobileNumberScreenView());
                                },
                                size: Size(0, ScreenSize.height(7, context)),
                                title: '',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: TextSpan(
                    text: "Not have an account? ".tr,
                    style: TextStyle(fontSize: 14, color: themeChange.isDarkTheme() ? AppThemeData.grey5 : AppThemeData.grey6, fontFamily: FontFamily.regular),
                    children: [
                      TextSpan(
                        text: "Sign Up".tr,
                        style: TextStyle(fontSize: 14, color: AppThemeData.secondary4, fontFamily: FontFamily.regular, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()..onTap = () => Get.to(SignupScreenView(), arguments: {"type": Constant.emailLoginType}),
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
          TextCustom(title: "Sign In to Your Account".tr, fontFamily: FontFamily.bold, fontSize: 24, color: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10),
          spaceH(height: 2),
          TextCustom(
            title: "Enter your details to continue buying and selling.".tr,
            fontSize: 16,
            fontFamily: FontFamily.regular,
            maxLine: 2,
            color: themeChange.isDarkTheme() ? AppThemeData.grey5 : AppThemeData.grey6,
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }

  Column buildEmailPasswordWidget(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Column(
      children: [
        TextFieldWidget(
          title: "Email".tr,
          hintText: "Enter email address".tr,
          validator: (value) => Constant.validateEmail(value),
          controller: controller.emailController.value,
          onPress: () {},
        ),
        spaceH(height: 16),
        Obx(
          () => TextFieldWidget(
            title: "Password".tr,
            hintText: "Enter password".tr,
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
                  height: 22,
                  width: 22,
                  color: themeChange.isDarkTheme() ? AppThemeData.grey5 : AppThemeData.grey6,
                ),
              ),
            ).paddingOnly(right: 4),
            onPress: () {},
          ),
        ),
      ],
    );
  }
}
