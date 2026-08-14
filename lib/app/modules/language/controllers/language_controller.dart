import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/models/language_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/preferences.dart';
import 'package:get/get.dart';

class LanguageController extends GetxController {
  /// Starts true so the picker shows a loader until languages arrive —
  /// previously it started false and was never raised, so on a cold first
  /// launch the screen rendered an empty list with no feedback.
  RxBool isLoading = true.obs;
  RxList<LanguageModel> languageList = <LanguageModel>[].obs;
  Rx<LanguageModel> selectedLanguage = LanguageModel().obs;

  @override
  void onInit() {
    getLanguage();
    super.onInit();
  }

  Future<void> getLanguage() async {
    isLoading.value = true;
    try {
      // On a cold app start (fresh APK install) the very first Firestore
      // fetch can race network/Firebase readiness and come back empty.
      // Retry a few times with a short backoff before giving up — this is
      // why the picker used to appear only after closing and reopening the
      // app (by then Firestore's local cache had the data).
      List<LanguageModel> data = const [];
      for (int attempt = 1; attempt <= 3; attempt++) {
        // Timeout each attempt: a request stuck behind cold-start plumbing
        // (network warm-up, token fetches) must not hang the picker forever.
        data = await FireStoreUtils.getLanguage().timeout(const Duration(seconds: 12), onTimeout: () => <LanguageModel>[]);
        if (data.isNotEmpty) break;
        if (attempt < 3) await Future.delayed(Duration(seconds: attempt));
      }

      languageList.assignAll(data);
      languageList.sort((a, b) {
        if (a.defaultLanguage == true) return -1;
        if (b.defaultLanguage == true) return 1;
        return 0;
      });

      // Guard: with no languages loaded there is nothing to preselect —
      // `.first` on an empty list used to throw and silently kill this
      // whole method.
      if (languageList.isEmpty) return;

      final savedLang = Preferences.getString(Preferences.languageCodeKey);

      // ✅ FIRST TIME (NO LANGUAGE SAVED)
      if (savedLang.isEmpty) {
        final defaultLang = languageList.firstWhere((e) => e.defaultLanguage == true, orElse: () => languageList.first);
        selectedLanguage.value = defaultLang;
      }
      // ✅ LANGUAGE ALREADY SAVED
      else {
        final temp = await Constant.getLanguage();
        final matched = languageList.firstWhere((e) => e.id == temp.id, orElse: () => languageList.first);
        selectedLanguage.value = matched;
      }
    } finally {
      isLoading.value = false;
    }
  }
}
