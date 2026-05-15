// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

class Styles {
  static ThemeData themeData(bool isDarkTheme, BuildContext context) {
    return ThemeData(
        scaffoldBackgroundColor: isDarkTheme ? AppThemeData.grey10 : AppThemeData.grey1,
        dialogBackgroundColor: isDarkTheme ? AppThemeData.grey10 : AppThemeData.grey2,
        primaryColor: AppThemeData.primary4,
        brightness: isDarkTheme ? Brightness.dark : Brightness.light,
        appBarTheme: AppBarTheme(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark, // Android → black
            statusBarBrightness: Brightness.light,    // iOS → black
          ),
        ),
        timePickerTheme: TimePickerThemeData(
            backgroundColor: isDarkTheme ? Color(0xff1A1A1A) : Color(0xffFFFFFF),
            dialTextStyle: TextStyle(fontWeight: FontWeight.bold, color: AppThemeData.grey10),
            dialTextColor: AppThemeData.grey10,
            hourMinuteTextColor: AppThemeData.primary2,
            dayPeriodTextColor: isDarkTheme ? AppThemeData.primaryWhite : AppThemeData.primaryBlack,
            dayPeriodColor: AppThemeData.primary2,
            dialHandColor: AppThemeData.primary2,
            hourMinuteColor: AppThemeData.primary2.withOpacity(0.2),
            dialBackgroundColor: isDarkTheme ? Color(0xff1F1F1F) : Color(0xffF6F7F9)),
        floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: AppThemeData.primary2, foregroundColor: AppThemeData.primaryWhite),
        dialogTheme: DialogThemeData(barrierColor: isDarkTheme
            ? AppThemeData.grey1.withOpacity(0.5)
            : AppThemeData.grey10.withOpacity(0.5),
            elevation: 10),
        popupMenuTheme: PopupMenuThemeData(color: isDarkTheme ? AppThemeData.grey10 : AppThemeData.grey1));
  }
}
