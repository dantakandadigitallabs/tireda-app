import 'package:eSellify/languages/app_en.dart';
import 'package:eSellify/languages/app_ha.dart';
import 'package:eSellify/languages/app_yo.dart';
import 'package:eSellify/languages/app_ig.dart'; // Import Igbo file
import 'package:flutter/material.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class LocalizationService extends Translations {
  static const locale = Locale('en', 'US');

  static final locales = [
    const Locale('en'),
    const Locale('ha'),
    const Locale('yo'),
    const Locale('ig'), // Add Igbo locale
  ];
  // Language display names (for language selector UI)

  /// Admin-configured ACTIVE language codes (from the `languages` collection,
  /// `active == true`), restricted to codes this app ships translations for.
  /// Empty until [ensureActiveCodesLoaded] completes; the language tab strip
  /// and the AI translation request use ONLY these codes, so sellers never
  /// see tabs for languages the admin has disabled.
  static final RxList<String> activeLanguageCodes = <String>[].obs;
  static bool _activeCodesRequested = false;

  /// Idempotent fetch of the admin's active languages. Safe to call from
  /// build methods; on failure the flag resets so a later call can retry.
  static Future<void> ensureActiveCodesLoaded() async {
    if (_activeCodesRequested) return;
    _activeCodesRequested = true;
    try {
      final langs = await FireStoreUtils.getLanguage();
      final supported = locales.map((l) => l.languageCode).toSet();
      final codes = langs
          .map((l) => (l.code ?? '').trim().toLowerCase())
          .where((c) => c.isNotEmpty && supported.contains(c))
          .toList();
      activeLanguageCodes.assignAll(codes);
    } catch (_) {
      _activeCodesRequested = false;
    }
  }


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