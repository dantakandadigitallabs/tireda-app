import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:eSellify/app/models/language_model.dart';
import 'package:eSellify/app/modules/language/views/language_view.dart';
import 'package:eSellify/app/modules/signup_screen/views/enter_location_view.dart';
import 'package:eSellify/app/routes/app_pages.dart';
import 'package:eSellify/app/services/localization_service.dart';
import 'package:eSellify/utils/preferences.dart';
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
    Timer(const Duration(seconds: 3), () {
      redirectScreen();
    });
  }

  Future<void> redirectScreen() async {
    try {
      final savedLang = Preferences.getString(Preferences.languageCodeKey);
      if (savedLang == "null" || savedLang.isEmpty) {
        Get.offAll(() => const LanguageView(isFirstTime: true));
        return;
      } else {
        final lang = LanguageModel.fromJson(jsonDecode(savedLang));
        LocalizationService().changeLocale(lang.code ?? "en");
      }

      bool isLogin = await FireStoreUtils.isLogin();
      if (!isLogin) {
        developer.log("User not logged in, going to login screen");
        await FirebaseAuth.instance.signOut();
        Get.offAllNamed(Routes.LOGIN_SCREEN);
        return;
      }

      Constant.userModel = await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()!);
      if (Constant.userModel == null) {
        developer.log("User model is null, signing out");
        await FirebaseAuth.instance.signOut();
        Get.offAllNamed(Routes.LOGIN_SCREEN);
        return;
      }

      developer.log("User isActive: ${Constant.userModel!.isActive}");
      developer.log("User addresses: ${Constant.userModel!.addAddresses?.length ?? 0}");

      if (Constant.userModel!.isActive != true) {
        developer.log("Account disabled");
        Get.offAll(const AccountDisabledScreen());
        return;
      }

      if (Constant.userModel!.addAddresses == null || Constant.userModel!.addAddresses!.isEmpty) {
        developer.log("No addresses found");
        Get.to(EnterLocationView(isRedirectDashboard: true));
        return;
      }

      developer.log("All good, going to dashboard");
      Get.offAll(const DashboardScreenView());
    } catch (e, stack) {
      developer.log("Error in redirectScreen: ", error: e, stackTrace: stack);
      Get.offAllNamed(Routes.LOGIN_SCREEN);
    }
  }
}
