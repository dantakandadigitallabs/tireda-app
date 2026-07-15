import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:country_code_picker/country_code_picker.dart';
import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/global_controller.dart';
import 'package:eSellify/app/constant/toast_service.dart';
import 'package:eSellify/app/modules/splash/views/splash_view.dart';
import 'package:eSellify/utils/app_colors.dart';
import 'package:eSellify/utils/dark_theme_provider.dart';
import 'package:eSellify/utils/ad_service.dart';
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

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
  );

  configLoading();
  Constant.getAddress();
  NotificationService().initInfo();
  runApp(const MyApp());
  // Tireda Custom: moved AdService.init() to after runApp() and made it
// fire-and-forget (was previously awaited mid-startup, blocking first frame
// for ad SDK init even though ads aren't currently active in the app)
  AdService.init();
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
    super.initState();
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
              locale: LocalizationService.locale,
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