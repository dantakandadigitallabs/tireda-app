import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:country_code_picker/country_code_picker.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/global_controller.dart';
import 'package:eSellify/app/constant/toast_service.dart';
import 'package:eSellify/app/modules/splash/views/splash_view.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/ad_service.dart';
import 'package:eSellify/utils/deep_link_service.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/notifications/notification_service.dart';
import 'package:eSellify/utils/preferences.dart';
import 'package:eSellify/utils/styles.dart';
import 'package:eSellify/app/services/localization_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // NOTE: We intentionally do NOT call FlutterNativeSplash.preserve()
  // so the native splash dismisses on its own as soon as Flutter renders
  // its first frame — regardless of how long Firebase takes to init.
  // This prevents the native splash from freezing on slow/no network.

  Preferences.initPref();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Apply Firestore settings to the resolved instance (default OR staging
  // per Constant.useStagingDb). This must run AFTER Firebase.initializeApp.
  FireStoreUtils.fireStore.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  configLoading();
  Constant.getAddress();
  NotificationService().initFirebaseCore();
  runApp(const MyApp());

  // Tireda Custom: moved AdService.init() to after runApp() and made it
  // fire-and-forget (was previously awaited mid-startup, blocking first frame
  // for ad SDK init even though ads aren't currently active in the app)
  AdService.init();

  // Firebase App Check — activated AFTER startup, deferred and non-fatal.
  //
  // Why: in a release build App Check uses Play Integrity. When the APK is
  // installed outside the Play Store (sideloaded for testing), the FIRST
  // Play Integrity attestation stalls for a very long time — and Firestore
  // requests issued after activation wait on that token fetch. Activating
  // before runApp therefore froze every first-launch read (the language
  // list stayed empty, Retry included) until the app was killed and
  // reopened (the failed attestation is cached across processes).
  // Deferring activation lets the critical startup reads go out untouched;
  // App Check still covers the rest of the session.
  Future.delayed(const Duration(seconds: 10), () async {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
      );
    } catch (e) {
      debugPrint('AppCheck activation failed (non-fatal): $e');
    }
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DarkThemeProvider themeChangeProvider = DarkThemeProvider();

  @override
  void initState() {
    getCurrentAppTheme();
    WidgetsBinding.instance.addObserver(this);
    // Start listening for incoming share links. Safe on all platforms;
    // becomes active once the platform-specific universal / app link
    // config is deployed (see the Android manifest /ad-detail intent filter).
    DeepLinkService.instance.init();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DeepLinkService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    getCurrentAppTheme();
  }

  void getCurrentAppTheme() async {
    themeChangeProvider.darkTheme =
    await themeChangeProvider.darkThemePreference.isDarkThemee();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: ChangeNotifierProvider(
        create: (_) => themeChangeProvider,
        child: Consumer<DarkThemeProvider>(
          builder: (context, value, child) {
            return GetMaterialApp(
              navigatorKey: navigatorKey,
              title: 'Tireda'.tr,
              debugShowCheckedModeBanner: false,
              theme: Styles.themeData(
                themeChangeProvider.darkTheme == 0
                    ? true
                    : themeChangeProvider.darkTheme == 1
                    ? false
                    : themeChangeProvider.getSystemThem(),
                context,
              ),
              darkTheme: Styles.themeData(true, context),
              themeMode: themeChangeProvider.darkTheme == 1
                  ? ThemeMode.light
                  : ThemeMode.dark,
              localizationsDelegates: const [CountryLocalizations.delegate],
              // Restore the previously-selected language on cold start.
              // Falls back to English when nothing is persisted or the
              // stored blob can't be parsed.
              locale: _loadInitialLocale(),
              fallbackLocale: LocalizationService.locale,
              translations: LocalizationService(),
              builder: EasyLoading.init(),
              initialRoute: AppPages.INITIAL,
              getPages: AppPages.routes,
              home: GetBuilder<GlobalController>(
                init: GlobalController(),
                builder: (context) {
                  return const SplashView();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Rehydrates the saved language code from Preferences so a hot
/// restart / reinstall boots the app in the user's last-picked
/// language instead of the hard-coded English default.
Locale _loadInitialLocale() {
  try {
    final raw = Preferences.getString(Preferences.languageCodeKey);
    if (raw.isEmpty) return LocalizationService.locale;
    final map = jsonDecode(raw);
    if (map is Map && map['code'] is String && (map['code'] as String).isNotEmpty) {
      return Locale(map['code'] as String);
    }
  } catch (_) {}
  return LocalizationService.locale;
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 45
    ..radius = 10
    ..progressColor = AppThemeData.primary4
    ..backgroundColor = AppThemeData.primaryWhite
    ..indicatorColor = AppThemeData.primary4
    ..textColor = AppThemeData.primary4
    ..maskColor = AppThemeData.primaryWhite
    ..dismissOnTap = false
    ..userInteractions = false;
}