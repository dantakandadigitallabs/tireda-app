import 'dart:developer' as developer;

import 'package:eSellify/app/models/category_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class CategoriesController extends GetxController {
  RxBool isLoading = true.obs;
  RxList<CategoryModel> categoryList = <CategoryModel>[].obs;

  @override
  void onInit() {
    getCategory();
    super.onInit();
  }

  Future<void> getCategory() async {
    isLoading.value = true;
    try {
      final category = await FireStoreUtils.getParentCategory();
      categoryList.value = category;
    } catch (e) {
      // Tireda Custom: defensive only — getParentCategory() already catches its own
      // errors and returns [] (shared across home/ads_listing/search controllers too,
      // so that contract is intentionally left untouched here). This guards against
      // any future exception between the call and assignment.
      developer.log('CategoriesController.getCategory Error: $e');
      categoryList.value = [];
    } finally {
      // Tireda Custom: guarantees isLoading never gets stuck true
      isLoading.value = false;
    }
  }

  /// Tireda Custom: lets the "No Categories Found" state offer a retry,
  /// in case the empty result was actually a transient fetch failure.
  Future<void> retry() async {
    await getCategory();
  }
}