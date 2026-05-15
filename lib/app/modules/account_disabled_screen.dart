// ignore_for_file: depend_on_referenced_packages

import 'package:eSellify/app/constant/round_shape_button.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/modules/login_screen/views/login_screen_view.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/screen_size.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class AccountDisabledScreen extends StatelessWidget {
  const AccountDisabledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey1,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 42),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset("assets/icons/ic_account_disabled.svg"),
            const SizedBox(
              height: 28,
            ),
            Text(
              "Your Account Has Been Disabled".tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontFamily: FontFamily.medium, color: themeChange.isDarkTheme() ? AppThemeData.primaryWhite : AppThemeData.primaryBlack),
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              "Access to your account has been disabled. please contact to the admin.".tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontFamily: FontFamily.regular, color: themeChange.isDarkTheme() ? AppThemeData.primaryWhite : AppThemeData.primaryBlack),
            ),
            SizedBox(
              height: 24,
            ),
            RoundShapeButton(
              title: "Log out".tr,
              buttonColor: AppThemeData.primary4,
              buttonTextColor: themeChange.isDarkTheme() ? AppThemeData.primaryBlack : AppThemeData.primaryWhite,
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Constant.userModel = null;
                if (context.mounted) {
                  Navigator.pop(context);
                }
                Get.offAll(LoginScreenView());
              },
              size: Size(358, ScreenSize.height(6, context)),
            )
          ],
        ),
      ),
    );
  }
}
