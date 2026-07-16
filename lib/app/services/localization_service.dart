import 'package:eSellify/languages/app_en.dart';
import 'package:eSellify/languages/app_ha.dart'; // 1. Import new file
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocalizationService extends Translations {
  static const locale = Locale('en', 'US');

  static final locales = [
    const Locale('en'),
    const Locale('ha'), // 2. Add to supported locales
  ];

  static final Map<String, String> languageNames = {
    'en': 'English',
    'ha': 'Hausa', // 3. Add to display names
  };

  @override
  Map<String, Map<String, String>> get keys => {
    'en': enUS,
    'ha': haHA, // 4. Register the map
  };

  void changeLocale(String lang) {
    Get.updateLocale(Locale(lang));
  }
}