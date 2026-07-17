import 'package:eSellify/languages/app_en.dart';
import 'package:eSellify/languages/app_ha.dart';
import 'package:eSellify/languages/app_yo.dart';
import 'package:eSellify/languages/app_ig.dart'; // Import Igbo file
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocalizationService extends Translations {
  static const locale = Locale('en', 'US');

  static final locales = [
    const Locale('en'),
    const Locale('ha'),
    const Locale('yo'),
    const Locale('ig'), // Add Igbo locale
  ];

  static final Map<String, String> languageNames = {
    'en': 'English',
    'ha': 'Hausa',
    'yo': 'Yorùbá',
    'ig': 'Igbo', // Add Igbo display name
  };

  @override
  Map<String, Map<String, String>> get keys => {
    'en': enUS,
    'ha': haHA,
    'yo': yoYO,
    'ig': igIG, // Register Igbo map
  };

  void changeLocale(String lang) {
    Get.updateLocale(Locale(lang));
  }
}