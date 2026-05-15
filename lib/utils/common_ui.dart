// ignore_for_file: deprecated_member_use

import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'app_colors.dart';
import 'font_family.dart';
import 'dark_theme_provider.dart';

class UiInterface {
  const UiInterface({Key? key});

  static TextCustom joinAppWidget() {
    return TextCustom(title: "join_app".trParams({"appName": Constant.appName.value}), fontSize: 16, fontFamily: FontFamily.regular, color: AppThemeData.secondary4);
  }

  static AppBar customAppBar(
    BuildContext context,
    DarkThemeProvider themeChange,
    String title, {
    bool isBack = true,
    Color? backgroundColor,
    Color iconColor = AppThemeData.grey10,
    Color textColor = AppThemeData.grey10,
    List<Widget>? actions,
    Function()? onBackTap,
  }) {
    return AppBar(
      title: Row(
        children: [
          if (isBack)
            Padding(
              padding: const EdgeInsets.only(left: 10.0, right: 2),
              child: InkWell(
                onTap: onBackTap ?? () => Get.back(),
                child: SvgPicture.asset(
                  "assets/icons/ic_arrow_left.svg",
                  colorFilter: ColorFilter.mode(themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10, BlendMode.srcIn),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              title.tr,
              style: TextStyle(color: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10, fontFamily: FontFamily.medium, fontSize: 18),
            ),
          ),
        ],
      ),
      backgroundColor: themeChange.isDarkTheme() ? backgroundColor ?? AppThemeData.primaryBlack : backgroundColor ?? AppThemeData.primaryWhite,
      automaticallyImplyLeading: false,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 8,
      surfaceTintColor: Colors.transparent,
      actions: actions,
    );
  }
}
