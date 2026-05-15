// ignore_for_file: strict_top_level_inference

import 'dart:developer';

import 'package:eSellify/widgets/text_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/app_colors.dart';
import '../utils/dark_theme_provider.dart';


Widget spaceH({double? height}) => SizedBox(height: height ?? 10.0);

Widget spaceW({double? width}) => SizedBox(width: width ?? 10.0);

void printLog(String data) => log(data.toString());

EdgeInsets paddingEdgeInsets({double horizontal = 16, double vertical = 16}) {
  return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
}

Container divider(context, {Color? color, double height = 1}) {
  final themeChange = Provider.of<DarkThemeProvider>(context);
  return Container(height: height, color: color ?? (themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey1));
}

Widget customRadioButton(context, {required parameter, dynamic onChangeOne, dynamic onChangeTwo, required String title, required String radioOne, required String radioTwo}) {
  final themeChange = Provider.of<DarkThemeProvider>(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      TextCustom(
        title: title,
        fontSize: 12,
      ),
      spaceH(height: 20),
      SizedBox(
          height: 50,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: onChangeOne,
                  child: Row(
                    children: [
                      parameter == radioOne
                          ?  Icon(Icons.radio_button_checked, color: AppThemeData.primary4, size: 18)
                          : Icon(Icons.circle_outlined, color: themeChange.isDarkTheme() ? AppThemeData.grey2 : AppThemeData.grey10, size: 18),
                      spaceW(width: 4),
                      TextCustom(title: radioOne)
                    ],
                  ),
                ),
              ),
              spaceW(),
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: onChangeTwo,
                  child: Row(children: [
                    parameter == radioTwo
                        ? Icon(Icons.radio_button_checked, color: AppThemeData.primary4, size: 18)
                        : Icon(Icons.circle_outlined, color: themeChange.isDarkTheme() ? AppThemeData.grey2 : AppThemeData.grey10, size: 18),
                    spaceW(width: 4),
                    TextCustom(title: radioTwo)
                  ]),
                ),
              )
            ],
          )),
    ],
  );
}
