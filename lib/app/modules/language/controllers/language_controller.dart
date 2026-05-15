import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/models/language_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:eSellify/utils/preferences.dart';
import 'package:get/get.dart';

class LanguageController extends GetxController {
  RxBool isLoading = false.obs;
  RxList<LanguageModel> languageList = <LanguageModel>[].obs;
  Rx<LanguageModel> selectedLanguage = LanguageModel().obs;

  @override
  void onInit() {
    getLanguage();
    super.onInit();
  }

  Future<void> getLanguage() async {
    final data = await FireStoreUtils.getLanguage();
    languageList.assignAll(data);
    languageList.sort((a, b) {
      if (a.defaultLanguage == true) return -1;
      if (b.defaultLanguage == true) return 1;
      return 0;
    });
    final savedLang = Preferences.getString(Preferences.languageCodeKey);

    // ✅ FIRST TIME (NO LANGUAGE SAVED)
    if (savedLang.isEmpty) {
      // ✅ SAFE DEFAULT CHECK
      final defaultLang = languageList.firstWhere((e) => e.defaultLanguage == true, orElse: () => languageList.first);

      selectedLanguage.value = defaultLang;
    }
    // ✅ LANGUAGE ALREADY SAVED
    else {
      final temp = await Constant.getLanguage();

      final matched = languageList.firstWhere((e) => e.id == temp.id, orElse: () => languageList.first);

      selectedLanguage.value = matched;
    }

    isLoading.value = false;
  }
}
