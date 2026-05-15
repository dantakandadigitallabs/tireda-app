import 'package:eSellify/app/constant/round_shape_button.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/models/user_model.dart';
import 'package:eSellify/app/modules/account_disabled_screen.dart';
import 'package:eSellify/app/modules/dashboard_screen/views/dashboard_screen_view.dart';
import 'package:eSellify/app/modules/login_screen/controllers/verify_otp_controller.dart';
import 'package:eSellify/app/modules/signup_screen/views/signup_screen_view.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/utils/common_ui.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/notifications/notification_service.dart';
import 'package:eSellify/utils/preferences.dart';
import 'package:eSellify/utils/screen_size.dart';
import 'package:eSellify/widgets/global_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';

import 'package:provider/provider.dart';

import 'package:eSellify/app/constant/show_toast.dart';

class VerifyOtpView extends GetView<VerifyOtpController> {
  VerifyOtpView({super.key});

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
      init: VerifyOtpController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey1,
          appBar: UiInterface.customAppBar(context, themeChange, "", backgroundColor: Colors.transparent),
          body: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Padding(
                padding: paddingEdgeInsets(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildTopWidget(context),
                    spaceH(height: 32),
                    Center(child: buildEmailPasswordWidget(context)),
                    spaceH(height: 34),
                    Obx(
                      () => controller.enterMobileNumberController.enableResend.value
                          ? Center(
                              child: GestureDetector(
                                onTap: () {
                                  controller.enterMobileNumberController.sendCode();
                                },
                                child: Text(
                                  "Resend OTP".tr,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppThemeData.secondary4,
                                    fontFamily: FontFamily.regular,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppThemeData.secondary4,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: RichText(
                                text: TextSpan(
                                  text: "Resend OTP in ".tr,
                                  style: TextStyle(fontFamily: FontFamily.regular, color: themeChange.isDarkTheme() ? AppThemeData.grey5 : AppThemeData.grey6, fontSize: 14),
                                  children: [
                                    TextSpan(
                                      text: "00:${controller.enterMobileNumberController.secondsRemaining.value.toString().padLeft(2, '0')} sec".tr,
                                      style: TextStyle(fontSize: 14, color: AppThemeData.secondary4, fontFamily: FontFamily.regular),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    spaceH(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: RoundShapeButton(
                            title: "Verify OTP".tr,
                            buttonColor: AppThemeData.primary4,
                            buttonTextColor: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
                            onTap: () async {
                              if (controller.otpCode.value.length == 6) {
                                ShowToastDialog.showLoader("Verify".tr);
                                try {
                                  PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: controller.verificationId.value, smsCode: controller.otpCode.value);
                                  String fcmToken = await NotificationService.getToken();

                                  final signInCredential = await FirebaseAuth.instance.signInWithCredential(credential);
                                  // ------------------ New User ------------------
                                  if (signInCredential.additionalUserInfo!.isNewUser) {
                                    UserModel userModel = UserModel();
                                    userModel.id = signInCredential.user!.uid;
                                    userModel.countryCode = controller.countryCode.value;
                                    userModel.phoneNumber = controller.mobileNumberController.value.text;
                                    userModel.loginType = Constant.phoneLoginType;
                                    userModel.fcmToken = fcmToken;
                                    ShowToastDialog.closeLoader();
                                    Get.off(SignupScreenView(), arguments: {"userModel": userModel});
                                    return;
                                  }
                                  // ------------------ Existing User ------------------
                                  final userExist = await FireStoreUtils.userExistOrNot(signInCredential.user!.uid);
                                  if (!userExist) {
                                    UserModel userModel = UserModel();
                                    userModel.id = signInCredential.user!.uid;
                                    userModel.countryCode = controller.countryCode.value;
                                    userModel.phoneNumber = controller.mobileNumberController.value.text;
                                    userModel.loginType = Constant.phoneLoginType;
                                    userModel.fcmToken = fcmToken;
                                    Get.off(SignupScreenView(), arguments: {"userModel": userModel});
                                    return;
                                  }
                                  UserModel? userModel = await FireStoreUtils.getUserProfile(signInCredential.user!.uid);
                                  if (userModel == null) {
                                    UserModel userModel = UserModel();
                                    userModel.id = signInCredential.user!.uid;
                                    userModel.countryCode = controller.countryCode.value;
                                    userModel.phoneNumber = controller.mobileNumberController.value.text;
                                    userModel.loginType = Constant.phoneLoginType;
                                    userModel.fcmToken = fcmToken;
                                    Get.off(SignupScreenView(), arguments: {"userModel": userModel});
                                    return;
                                  }

                                  Constant.userModel = userModel;
                                  userModel.fcmToken = fcmToken;
                                  await FireStoreUtils.updateUser(userModel);
                                  if (userModel.isActive == true) {
                                    Preferences.setBoolean(Preferences.isFinishOnBoardingKey, true);
                                    await Constant.getAddress();
                                    Get.offAll(const DashboardScreenView());
                                  } else {
                                    Get.offAll(const AccountDisabledScreen());
                                  }
                                } catch (e) {
                                  ShowToastDialog.showError("Invalid verification code.".tr);
                                } finally {
                                  ShowToastDialog.closeLoader();
                                }
                              } else {
                                ShowToastDialog.showError("Please enter a valid OTP.".tr);
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
          Text(
            "Verify Your Account".tr,
            style: TextStyle(fontFamily: FontFamily.bold, fontSize: 24, color: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10),
          ),
          spaceH(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    text: "Enter the 6-digit code we sent to your phone ".tr,
                    style: TextStyle(fontFamily: FontFamily.regular, color: themeChange.isDarkTheme() ? AppThemeData.grey6 : AppThemeData.grey5, fontSize: 16),
                    children: [
                      TextSpan(
                        text: Constant.maskMobileNumber(countryCode: controller.countryCode.value, mobileNumber: controller.mobileNumberController.value.text),
                        style: TextStyle(fontSize: 16, fontFamily: FontFamily.regular, color: themeChange.isDarkTheme() ? AppThemeData.grey2 : AppThemeData.grey9),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 8),

              GestureDetector(
                onTap: () {
                  Get.back();
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppThemeData.primary4.withOpacity(0.1), shape: BoxShape.circle),
                  child: SvgPicture.asset("assets/icons/ic_edit.svg", width: 16, height: 16),
                ),
              ),
            ],
          ),
          spaceH(height: 24),
        ],
      ),
    );
  }

  OtpTextField buildEmailPasswordWidget(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return OtpTextField(
      fieldWidth: 46,
      borderWidth: 1,
      numberOfFields: 6,
      filled: true,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      cursorColor: AppThemeData.primary4,
      borderRadius: BorderRadius.circular(10),
      textStyle: TextStyle(fontSize: 16, fontFamily: FontFamily.regular, color: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10),
      borderColor: themeChange.isDarkTheme() ? AppThemeData.grey8 : AppThemeData.grey3,
      enabledBorderColor: themeChange.isDarkTheme() ? AppThemeData.grey8 : AppThemeData.grey3,
      disabledBorderColor: themeChange.isDarkTheme() ? AppThemeData.grey8 : AppThemeData.grey3,
      fillColor: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey1,
      focusedBorderColor: AppThemeData.primary4,
      showFieldAsBox: true,
      onSubmit: (value) {
        controller.otpCode.value = value;
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}
