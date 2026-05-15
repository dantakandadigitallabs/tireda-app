// ignore_for_file: constant_identifier_names

import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

class DarkThemePreference {
  static const THEME_STATUS = "THEMESTATUS";

  Future<void> setDarkTheme(int value) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(THEME_STATUS, value);
    } catch (e, stack) {
      developer.log("Error saving theme preference: ", error: e, stackTrace: stack);
    }
  }

  Future<int> isDarkThemee() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getInt(THEME_STATUS) ?? 2;
    } catch (e, stack) {
      developer.log("Error loading theme preference: ", error: e, stackTrace: stack);
      return 2; // fallback value
    }
  }
}
