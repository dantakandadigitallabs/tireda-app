import 'package:eSellify/languages/app_ar.dart';
import 'package:eSellify/languages/app_de.dart';
import 'package:eSellify/languages/app_en.dart';
import 'package:eSellify/languages/app_es.dart';
import 'package:eSellify/languages/app_fr.dart';
import 'package:eSellify/languages/app_hi.dart';
import 'package:eSellify/languages/app_id.dart';
import 'package:eSellify/languages/app_it.dart';
import 'package:eSellify/languages/app_ja.dart';
import 'package:eSellify/languages/app_ko.dart';
import 'package:eSellify/languages/app_pt.dart';
import 'package:eSellify/languages/app_ru.dart';
import 'package:eSellify/languages/app_tr.dart';
import 'package:eSellify/languages/app_zh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocalizationService extends Translations {
  // Default locale
  static const locale = Locale('en', 'US');

  // Supported locales
  static final locales = [
    const Locale('en'),    // English
    const Locale('hi'),    // Hindi
    const Locale('ar'),    // Arabic
    const Locale('es'),    // Spanish
    const Locale('fr'),    // French
    const Locale('pt'),    // Portuguese
    const Locale('zh'),    // Chinese (Simplified)
    const Locale('ru'),    // Russian
    const Locale('tr'),    // Turkish
    const Locale('de'),    // German
    const Locale('ja'),    // Japanese
    const Locale('ko'),    // Korean
    const Locale('id'),    // Indonesian
    const Locale('it'),    // Italian
  ];

  // Language display names (for language selector UI)
  static final Map<String, String> languageNames = {
    'en': 'English',
    'hi': 'हिन्दी',
    'ar': 'العربية',
    'es': 'Español',
    'fr': 'Français',
    'pt': 'Português',
    'zh': '中文',
    'ru': 'Русский',
    'tr': 'Türkçe',
    'de': 'Deutsch',
    'ja': '日本語',
    'ko': '한국어',
    'id': 'Bahasa Indonesia',
    'it': 'Italiano',
  };

  @override
  Map<String, Map<String, String>> get keys => {
    'en': enUS,
    'hi': hiIN,
    'ar': lnAr,
    'es': esES,
    'fr': frFR,
    'pt': ptBR,
    'zh': zhCN,
    'ru': ruRU,
    'tr': trTR,
    'de': deDE,
    'ja': jaJP,
    'ko': koKR,
    'id': idID,
    'it': itIT,
  };

  // Gets locale from language, and updates the locale
  void changeLocale(String lang) {
    Get.updateLocale(Locale(lang));
  }
}
