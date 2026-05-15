// ignore_for_file: deprecated_member_use

import 'dart:developer' as developer;

//import 'package:customer/utils/notification_service.dart';
import 'package:eSellify/app/models/currency_model.dart';
import 'package:eSellify/app/models/user_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/notifications/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'constants.dart';

class GlobalController extends GetxController {
  @override
  Future<void> onInit() async {
    await getSettingData();
    notificationInit();
    await getCurrentCurrency();
    _runExpiryChecks();
    super.onInit();
  }

  /// Run auto-expiry checks for current user (fire-and-forget)
  void _runExpiryChecks() {
    final uid = FireStoreUtils.getCurrentUid();
    if (uid == null) return;
    // Fire-and-forget — don't block app startup
    FireStoreUtils.runExpiryChecks(uid).catchError((e) {
      developer.log("Expiry checks error: $e");
    });
  }

  Future<void> getSettingData() async {
    await FireStoreUtils().getSettings();
    // Load admin-configured app / web URLs so Share + download CTAs use them.
    // Fire-and-forget — defaults to empty strings if it fails.
    FireStoreUtils.getContactUsInformation().catchError((_) => null);
    if (Constant.customerAppColor != null && Constant.customerAppColor!.isNotEmpty) {
      AppThemeData.primary4 = HexColor.fromHex(Constant.customerAppColor!);
    }
    // Precache app logo so it shows instantly on splash
    _precacheAppLogo();
  }

  void _precacheAppLogo() {
    final urls = [Constant.appIconLight, Constant.appIconDark].whereType<String>().where((u) => u.isNotEmpty && u.startsWith('http'));
    for (final url in urls) {
      try {
        CachedNetworkImageProvider(url).resolve(const ImageConfiguration());
      } catch (_) {}
    }
  }

  Future<void> getCurrentCurrency() async {
    try {
      // First try to get admin-set default currency from settings/constant
      final settingsDoc = await FireStoreUtils.fireStore.collection('settings').doc('constant').get();
      if (settingsDoc.exists && settingsDoc.data()?['defaultCurrency'] != null) {
        Constant.currencyModel = CurrencyModel.fromJson(Map<String, dynamic>.from(settingsDoc.data()!['defaultCurrency']));
      } else {
        // Fallback to first active currency
        final value = await FireStoreUtils().getCurrency();
        if (value != null) {
          Constant.currencyModel = value;
        } else {
          Constant.currencyModel = CurrencyModel(id: "", code: "USD", decimalDigits: 2, enable: true, name: "US Dollar", symbol: "\$", symbolAtRight: false);
        }
      }
    } catch (e) {
      developer.log("Error fetching currency: $e");
      Constant.currencyModel = CurrencyModel(id: "", code: "USD", decimalDigits: 2, enable: true, name: "US Dollar", symbol: "\$", symbolAtRight: false);
    }

    try {
      await FireStoreUtils().getPayment();
    } catch (e) {
      developer.log("Error fetching payment settings: $e");
    }

    try {
      // AppThemeData.primary4 = HexColor.fromHex(Constant.appColor.toString());
    } catch (e) {
      developer.log("Error setting app color: $e");
    }
  }

  NotificationService notificationService = NotificationService();

  Future<void> notificationInit() async {
    try {
      await notificationService.initInfo();
      String token = await NotificationService.getToken();

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          final value = await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()!);
          if (value != null) {
            UserModel userModel = value;
            userModel.fcmToken = token;
            await FireStoreUtils.updateUser(userModel);
          }
        } catch (e) {
          developer.log("Error updating user FCM token: $e");
        }
      }
    } catch (e) {
      developer.log("Error initializing notification: $e");
    }
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      developer.log("Invalid hex color: $hexString - Error: $e");
      return Colors.transparent; // fallback to a safe default
    }
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) =>
      '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}
