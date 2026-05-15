import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const languageCodeKey = "languageCodeKey";
  static const themKey = "themKey";
  static const isFinishOnBoardingKey = "isFinishOnBoardingKey";
  static const String notificationPlayload = "notificationPlayload";
  static const String notificationData = "notificationData";
  static const selectedAddressKey = "selectedAddressKey";

  static late SharedPreferences pref;

  static Future<void> initPref() async {
    try {
      pref = await SharedPreferences.getInstance();
    } catch (e) {
      developer.log("Error initializing SharedPreferences: $e");
    }
  }

  static bool getBoolean(String key) {
    try {
      return pref.getBool(key) ?? false;
    } catch (e) {
      developer.log("Error getting boolean from SharedPreferences: $e");
      return false;
    }
  }

  static Future<void> setBoolean(String key, bool value) async {
    try {
      await pref.setBool(key, value);
    } catch (e) {
      developer.log("Error setting boolean in SharedPreferences: $e");
    }
  }

  static String getString(String key) {
    try {
      return pref.getString(key) ?? "";
    } catch (e) {
      developer.log("Error getting string from SharedPreferences: $e");
      return "";
    }
  }

  static Future<void> setString(String key, String value) async {
    try {
      await pref.setString(key, value);
    } catch (e) {
      developer.log("Error setting string in SharedPreferences: $e");
    }
  }

  static int getInt(String key) {
    try {
      return pref.getInt(key) ?? 0;
    } catch (e) {
      developer.log("Error getting int from SharedPreferences: $e");
      return 0;
    }
  }

  static Future<void> setInt(String key, int value) async {
    try {
      await pref.setInt(key, value);
    } catch (e) {
      developer.log("Error setting int in SharedPreferences: $e");
    }
  }

  static Future<void> clearSharPreference() async {
    try {
      await pref.clear();
    } catch (e) {
      developer.log("Error clearing SharedPreferences: $e");
    }
  }

  static Future<void> clearKeyData(String key) async {
    try {
      await pref.remove(key);
    } catch (e) {
      developer.log("Error removing key '$key' from SharedPreferences: $e");
    }
  }
}
