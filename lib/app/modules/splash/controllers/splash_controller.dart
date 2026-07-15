import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:eSellify/app/models/language_model.dart';
import 'package:eSellify/app/modules/language/views/language_view.dart';
import 'package:eSellify/app/modules/signup_screen/views/enter_location_view.dart';
import 'package:eSellify/app/services/localization_service.dart';
import 'package:eSellify/utils/preferences.dart';
import 'package:eSellify/utils/network_utils.dart';
import 'package:eSellify/widgets/no_connection_screen.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/modules/account_disabled_screen.dart';
import 'package:eSellify/app/modules/dashboard_screen/views/dashboard_screen_view.dart';
import 'package:eSellify/utils/fire_store_utils.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    // Tireda Custom: reduced from 3s to 2s — splash animation is 1.6s, so this
    // still gives a small buffer without the extra dead time
    Timer(const Duration(seconds: 2), () {
      redirectScreen();
    });
  }

  Future<void> redirectScreen() async {
    try {
      // ── Network check first ───────────────────────────────────────────────
      final hasNetwork = await NetworkUtils.isConnected(showError: false);
      if (!hasNetwork) {
        Get.offAll(() => NoConnectionScreen(onRetry: redirectScreen));
        return;
      }

      // ── Language check ────────────────────────────────────────────────────
      final savedLang = Preferences.getString(Preferences.languageCodeKey);
      if (savedLang == "null" || savedLang.isEmpty) {
        Get.offAll(() => const LanguageView(isFirstTime: true));
        return;
      } else {
        final lang = LanguageModel.fromJson(jsonDecode(savedLang));
        LocalizationService().changeLocale(lang.code ?? "en");
      }

      // ── Auth check — guest flows straight to dashboard ────────────────────
      bool isLogin = await FireStoreUtils.isLogin();
      if (isLogin) {
        Constant.userModel = await FireStoreUtils.getUserProfile(
          FireStoreUtils.getCurrentUid()!,
        );

        if (Constant.userModel == null) {
          developer.log("User model is null, signing out");
          await FirebaseAuth.instance.signOut();
        } else if (Constant.userModel!.isActive != true) {
          developer.log("Account disabled");
          Get.offAll(const AccountDisabledScreen());
          return;
        } else if (Constant.userModel!.addAddresses == null ||
            Constant.userModel!.addAddresses!.isEmpty) {
          developer.log("No addresses found");
          Get.to(EnterLocationView(isRedirectDashboard: true));
          return;
        }
      }

      // Guest or logged-in user both land on Dashboard
      developer.log("Going to dashboard — isLogin: $isLogin");
      Get.offAll(const DashboardScreenView());
    } catch (e, stack) {
      developer.log("Error in redirectScreen: ", error: e, stackTrace: stack);
      Get.offAll(const DashboardScreenView());
    }
  }
}