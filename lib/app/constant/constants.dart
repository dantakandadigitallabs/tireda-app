// ignore_for_file: depend_on_referenced_packages, non_constant_identifier_names, deprecated_member_use
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/models/add_address_model.dart';
import 'package:eSellify/app/models/language_model.dart';
import 'package:eSellify/app/models/payment_method_model.dart';
import 'package:eSellify/app/models/user_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_colors.dart';
import '../../utils/dark_theme_provider.dart';
import '../dependency/shimmer.dart';
import '../../utils/font_family.dart';
import '../../widgets/permission_dialog.dart';
import '../models/advertisement_config_model.dart';
import '../models/currency_model.dart';
import '../models/openai_config_model.dart';
import 'package:uuid/uuid.dart';

enum Status { active, inactive }

class Constant {

  /// Raster-image extensions accepted anywhere the user picks an image.
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif'];

  /// True when [name] (file name or path) carries an allowed image extension.
  static bool isAllowedImageFile(String name) {
    final n = name.split('?').first.toLowerCase();
    final dot = n.lastIndexOf('.');
    if (dot < 0 || dot == n.length - 1) return false;
    return allowedImageExtensions.contains(n.substring(dot + 1));
  }

  /// Gate for a single picked file: returns it when it is a real image,
  /// otherwise shows an error toast and returns null so callers treat it
  /// exactly like a cancelled pick.
  static XFile? validatePickedImage(XFile? file) {
    if (file == null) return null;
    if (isAllowedImageFile(file.name.isNotEmpty ? file.name : file.path)) return file;
    ShowToastDialog.showError("Only image files are allowed (JPG, PNG, GIF, WEBP).".tr);
    return null;
  }

  /// Gate for a multi-pick: keeps only real images and warns when anything
  /// was skipped.
  static List<XFile> validatePickedImages(List<XFile> files) {
    final ok = files.where((f) => isAllowedImageFile(f.name.isNotEmpty ? f.name : f.path)).toList();
    if (ok.length != files.length) {
      ShowToastDialog.showError("Some files were skipped — only image files are allowed.".tr);
    }
    return ok;
  }
  /// Toggle between Firestore databases. `false` → the project's `(default)`
  /// database; `true` → the `staging` named database. All reads/writes go
  /// through [FireStoreUtils.fireStore], which resolves this flag at
  /// startup — flip once here, no per-call plumbing required.
  static const bool useStagingDb = false;

  /// Name of the named database used when [useStagingDb] is true. Must
  /// match the database ID created in the Firebase console.
  static const String stagingDbId = 'staging';


  static RxString appName = "Tireda".obs;
  static String? appIconLight;
  static String? appIconDark;
  // Admin-configured watermark image URL. Empty string means "use the bundled
  // logo.svg fallback". Reactive so widgets in an Obx rebuild live when the
  // admin updates it in the App Settings page.
  static RxString watermarkUrl = ''.obs;

  /// Admin-configured app download / web links (from `settings/contact_us`).
  /// Share feature and "Rate the app" / "Download" CTAs use these so URLs
  /// can be updated without re-releasing the app.
  static RxString androidAppUrl = ''.obs;
  static RxString iosAppUrl = ''.obs;

  /// Base URL of the customer web app (used to build shareable ad links
  /// so recipients can open the ad in a browser even without the mobile
  /// app). Pulled from admin settings at startup.
  /// Example: "https://esellify.com"
  static RxString webAppUrl = ''.obs;

  static const String googleLoginType = 'google';
  static const String appleLoginType = "apple";
  static const String emailLoginType = "email";
  static String phoneLoginType = 'phone';
  static String user = 'user';

  static String? customerAppColor;

  static const userPlaceHolder = 'assets/images/user_placeholder.png';

  static UserModel? userModel;
  static String senderId = "";

  // Ad Settings (from settings/ad_settings)
  static bool autoApproveAds = false;
  static bool autoApproveEditedAds = false;
  static bool freeAdListing = false;
  static bool freeAdFeaturing = false;
  static bool unlimitedAdDuration = false;
  static int freeAdListingDays = 30;
  static int minRange = 50;
  static int maxRange = 200;

  static Rxn<AddAddressModel> currentLocation = Rxn<AddAddressModel>();
  static CurrencyModel? currencyModel;
  static AdvertisementConfigModel? advertisementConfig;

  static PaymentModel? paymentModel;

  static int pageSize = 10;

  static String? selectedMap;

  static String jsonFileURL = "";
  static String googleMapKey = "";
  static String? countryCode = '+234';
  static String termsAndConditions = "";
  static String privacyPolicy = "";
  static String aboutApp = "";
  /// Each entry is the raw `tip` field from Firestore — either a flat
  /// String (legacy) or `Map<code, String>` (localized). The bottom
  /// sheet picks the right language at render time via [safetyTipFor]
  /// so switching app language mid-session refreshes the tips without
  /// re-fetching.
  static List<dynamic> safetyTips = [];

  /// Resolves one raw entry from [safetyTips] into a display string
  /// using the app's currently selected locale, falling back
  /// `default` → `en` → first non-empty.
  static String safetyTipFor(dynamic raw, String? code) {
    if (raw is String) return raw;
    if (raw is Map) {
      final map = <String, String>{};
      raw.forEach((k, v) {
        if (v is String && v.isNotEmpty) map[k.toString()] = v;
      });
      if (map.isEmpty) return '';
      if (code != null && (map[code] ?? '').isNotEmpty) return map[code]!;
      if ((map['default'] ?? '').isNotEmpty) return map['default']!;
      if ((map['en'] ?? '').isNotEmpty) return map['en']!;
      return map.values.first;
    }
    return '';
  }
  static OpenAiConfigModel openAiConfig = OpenAiConfigModel(enabled: false);

  static const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  static final Random _rnd = Random();

  static String getRandomString(int length) => String.fromCharCodes(Iterable.generate(length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  static TextStyle defaultTextStyle({double size = 24.00, Color color = Colors.black}) {
    return TextStyle(fontSize: size, color: color, fontWeight: FontWeight.w600, fontFamily: FontFamily.medium);
  }

  static Widget loader({BuildContext? context}) {
    bool isDark = false;
    if (context != null) {
      try {
        isDark = Provider.of<DarkThemeProvider>(context, listen: false).isDarkTheme();
      } catch (_) {}
    }
    final base = isDark ? AppThemeData.grey9 : AppThemeData.grey3;
    final highlight = isDark ? AppThemeData.grey8 : AppThemeData.grey2;
    final color = isDark ? AppThemeData.primaryBlack : AppThemeData.primaryWhite;

    return Center(
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 14,
              width: 180,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 10),
            Container(
              height: 14,
              width: 140,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 10),
            Container(
              height: 14,
              width: 160,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> getAddress() async {
    if (FireStoreUtils.getCurrentUid() == null) {
      if (Preferences.getString(Preferences.selectedAddressKey).isNotEmpty) {
        AddAddressModel addressModel = AddAddressModel.fromJson(jsonDecode(Preferences.getString(Preferences.selectedAddressKey)));
        currentLocation.value = addressModel;
      }
    } else {
      final user = await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid().toString());
      if (user != null) {
        userModel = user;
        // Prefer the address the user last SELECTED (persisted in prefs) over
        // the one flagged isDefault — otherwise re-opening the app forgets the
        // active selection and the Home Screen sorts by the wrong location.
        AddAddressModel? preferred;
        final savedRaw = Preferences.getString(Preferences.selectedAddressKey);
        if (savedRaw.isNotEmpty) {
          try {
            final saved = AddAddressModel.fromJson(jsonDecode(savedRaw));
            if (saved.id != null && (userModel?.addAddresses ?? []).any((a) => a.id == saved.id)) {
              preferred = (userModel!.addAddresses!).firstWhere((a) => a.id == saved.id);
            }
          } catch (_) {}
        }
        preferred ??= (userModel?.addAddresses ?? []).firstWhere(
              (element) => element.isDefault == true,
          orElse: () => (userModel!.addAddresses!.isNotEmpty ? userModel!.addAddresses!.first : AddAddressModel()),
        );
        if (userModel!.addAddresses!.isNotEmpty) {
          currentLocation.value = preferred;
        } else if (savedRaw.isNotEmpty) {
          currentLocation.value = AddAddressModel.fromJson(jsonDecode(savedRaw));

        }
      }
    }
  }

  static void checkPermission(Function() onTap) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        ShowToastDialog.showError("You have to allow location permission to use your location".tr);
      } else if (permission == LocationPermission.deniedForever) {
        showDialog(
          context: Get.context!,
          builder: (BuildContext context) {
            return const PermissionDialog();
          },
        );
      } else {
        onTap();
      }
    } catch (e, stack) {
      developer.log('Error checking location permission: ', error: e, stackTrace: stack);
    }
  }

  static bool hasValidUrl(String value) {
    String pattern = r'(http|https)://[\w-]+(\.[\w-]+)+([\w.,@?^=%&amp;:/~+#-]*[\w@?^=%&amp;/~+#-])?';
    RegExp regExp = RegExp(pattern);
    if (value.isEmpty) {
      return false;
    } else if (!regExp.hasMatch(value)) {
      return false;
    }
    return true;
  }

  static String? validateEmail(String? value) {
    String pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(value ?? '')) {
      return 'Enter valid email';
    } else {
      return null;
    }
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty || value.length < 6) {
      return "Minimum password length should be 6";
    } else {
      return null;
    }
  }

  static String maskMobileNumber({String? mobileNumber, String? countryCode}) {
    String maskedNumber = 'x' * (mobileNumber!.length - 2) + mobileNumber.substring(mobileNumber.length - 2);
    return "$countryCode $maskedNumber";
  }

  static String amountShow({required String? amount}) {
    if (amount == null || amount.isEmpty) {
      return "N/A";
    }

    final parsedAmount = double.tryParse(amount);
    if (parsedAmount == null) {
      return "Invalid Amount";
    }

    if (Constant.currencyModel != null) {
      if (Constant.currencyModel!.symbolAtRight == true) {
        return "${parsedAmount.toStringAsFixed(Constant.currencyModel!.decimalDigits!)} ${Constant.currencyModel!.symbol.toString()}";
      } else {
        return "${Constant.currencyModel!.symbol.toString()} ${parsedAmount.toStringAsFixed(Constant.currencyModel!.decimalDigits!)}";
      }
    }
    return '';
  }

  static Future<String> uploadImageToFireStorage(File image, String filePath, String fileName) async {
    try {
      Reference upload = FirebaseStorage.instance.ref().child('$filePath/$fileName');
      UploadTask uploadTask = upload.putFile(image);
      var downloadUrl = await (await uploadTask.whenComplete(() {})).ref.getDownloadURL();
      return downloadUrl.toString();
    } catch (e) {
      developer.log('Error uploading image to Firestore: ', error: e);
      rethrow;
    }
  }

  static Future<LanguageModel> getLanguage() async {
    try {
      final String user = Preferences.getString(Preferences.languageCodeKey);
      Map<String, dynamic> userMap = jsonDecode(user);
      return LanguageModel.fromJson(userMap);
    } catch (e) {
      developer.log('Error getting language: ', error: e);
      return LanguageModel(id: "biqcXAhdxABnCVJDhnYI", code: "en", name: "English");
    }
  }

  static Future<void> redirectMail({required String email}) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      debugPrint('Could not launch email');
    }
  }

  static Future<void> redirectCall({required String countryCode, required String phoneNumber}) async {
    final Uri url = Uri.parse("tel:$countryCode $phoneNumber");
    if (!await launchUrl(url)) {
      throw Exception('Could not launch '.tr);
    }
  }

  static InputDecoration DefaultInputDecoration(BuildContext context, {Color? fillColor}) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return InputDecoration(
      iconColor: AppThemeData.primary4,
      isDense: true,
      filled: true,
      fillColor: fillColor ?? (themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey1),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      disabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(color: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(color: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(color: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(color: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey2),
      ),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(color: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey2),
      ),
      hintText: "Select Brand".tr,
      hintStyle: TextStyle(fontSize: 14, color: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey2, fontWeight: FontWeight.w500, fontFamily: FontFamily.medium),
    );
  }

  static InputDecoration DefaultInputDecorationForDrawerWidgets(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return InputDecoration(
      iconColor: AppThemeData.primary4,
      isDense: true,
      filled: true,
      fillColor: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey1,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      disabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(color: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(color: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(color: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(color: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey2),
      ),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(color: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey2),
      ),
      hintText: "Select Brand".tr,
      hintStyle: TextStyle(fontSize: 14, color: themeChange.isDarkTheme() ? AppThemeData.grey10 : AppThemeData.grey2, fontWeight: FontWeight.w500, fontFamily: FontFamily.medium),
    );
  }

  static String fullNameString(String? firstName, String? lastName) {
    try {
      return '${firstName ?? ''} ${lastName ?? ''}'.trim();
    } catch (e) {
      return '';
    }
  }

  static List<String> generateKeywords(String text) {
    if (text.isEmpty) return [];

    final lower = text.toLowerCase().trim();
    final List<String> keywords = [];

    final words = lower.split(' ').where((w) => w.isNotEmpty).toList();

    for (int i = 0; i < words.length; i++) {
      for (int j = i + 1; j <= words.length; j++) {
        keywords.add(words.sublist(i, j).join(' '));
      }
    }

    for (var word in words) {
      for (int i = 1; i <= word.length; i++) {
        keywords.add(word.substring(0, i));
      }
    }

    for (int i = 1; i <= lower.length; i++) {
      keywords.add(lower.substring(0, i));
    }

    return keywords.toSet().toList();
  }

  static List<String> generateSearchKeywords(String text) {
    if (text.isEmpty) return [];

    final lower = text.toLowerCase().trim();
    final List<String> keywords = [];

    final words = lower.split(' ').where((w) => w.isNotEmpty).toList();

    for (int i = 0; i < words.length; i++) {
      for (int j = i + 1; j <= words.length; j++) {
        keywords.add(words.sublist(i, j).join(' '));
      }
    }

    for (var word in words) {
      for (int i = 1; i <= word.length; i++) {
        keywords.add(word.substring(0, i));
      }
    }

    for (int i = 1; i <= lower.length; i++) {
      keywords.add(lower.substring(0, i));
    }

    return keywords.toSet().toList();
  }

  static String getUuid() {
    try {
      return const Uuid().v4();
    } catch (e, stack) {
      developer.log('Error generating UUID: ', error: e, stackTrace: stack);
      return '';
    }
  }

  static Future<String> getPackageName() async {
    final info = await PackageInfo.fromPlatform();
    return info.packageName;
  }
}

class StatusDetails {
  final String text;
  final Color textColor;
  final Color backgroundColor;

  StatusDetails({required this.text, required this.textColor, required this.backgroundColor});
}
