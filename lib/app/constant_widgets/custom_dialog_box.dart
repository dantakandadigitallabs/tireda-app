// ignore_for_file: strict_top_level_inference

import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/font_family.dart';
import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomDialogBox extends StatelessWidget {
  final String title, descriptions, positiveString, negativeString;
  final Widget img;
  final Function() positiveClick;
  final Function() negativeClick;
  final DarkThemeProvider themeChange;
  final Color? negativeButtonColor;
  final Color? positiveButtonColor;
  final Color? negativeButtonTextColor;
  final Color? positiveButtonTextColor;
  final Color? negativeButtonBorderColor;
  final Color? positiveButtonBorderColor;

  const CustomDialogBox({
    super.key,
    required this.title,
    required this.descriptions,
    required this.img,
    required this.positiveClick,
    required this.negativeClick,
    required this.positiveString,
    required this.negativeString,
    required this.themeChange,
    this.negativeButtonColor,
    this.positiveButtonColor,
    this.negativeButtonTextColor,
    this.positiveButtonTextColor,
    this.negativeButtonBorderColor,
    this.positiveButtonBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }

  Container contentBox(context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 20, right: 16, bottom: 20),
      decoration: BoxDecoration(shape: BoxShape.rectangle, color: themeChange.isDarkTheme() ? Colors.black : Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          img,
          const SizedBox(height: 16),
          Visibility(
            visible: title.isNotEmpty,
            child: TextCustom(title: title, fontSize: 24, fontFamily: FontFamily.bold, color: themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10),
          ).paddingOnly(bottom: 4),
          Visibility(
            visible: descriptions.isNotEmpty,
            child: TextCustom(
              maxLine: 4,
              title: descriptions,
              fontSize: 14,
              fontFamily: FontFamily.regular,
              color: themeChange.isDarkTheme() ? AppThemeData.grey6 : AppThemeData.grey5,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    negativeClick();
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: negativeButtonColor ?? AppThemeData.danger300,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: negativeButtonBorderColor ?? (negativeButtonColor ?? AppThemeData.danger300)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextCustom(title: negativeString.toString(), textAlign: TextAlign.center, fontSize: 14, color: negativeButtonTextColor ?? AppThemeData.primaryWhite),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    positiveClick();
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: positiveButtonColor ?? AppThemeData.primary4,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: positiveButtonBorderColor ?? (positiveButtonColor ?? AppThemeData.primary4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextCustom(
                          title: positiveString.toString(),
                          textAlign: TextAlign.center,
                          fontSize: 14,
                          color: positiveButtonTextColor ?? (themeChange.isDarkTheme() ? AppThemeData.grey1 : AppThemeData.grey10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
