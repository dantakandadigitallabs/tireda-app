import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/constant/show_toast.dart';
import 'package:eSellify/app/models/category_model.dart';
import 'package:eSellify/app/modules/subscriptions/views/subscriptions_view.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class SellScreenController extends GetxController {
  RxBool isLoading = true.obs;

  RxList<CategoryModel> allCategories = <CategoryModel>[].obs;
  RxList<CategoryModel> categoryList = <CategoryModel>[].obs;

  @override
  void onInit() {
    getCategory();
    super.onInit();
  }

  Future<void> getCategory() async {
    final category = await FireStoreUtils.getAllCategory();
    allCategories.value = category;
    categoryList.value = category.where((e) => e.parentCategoryId == null || e.parentCategoryId!.isEmpty).toList();
    isLoading.value = false;
  }

  List<CategoryModel> getSubCategory(String parentId) {
    final list = allCategories.where((e) {
      return (e.parentCategoryId ?? "").toString().trim() == parentId.toString().trim();
    }).toList();
    // Tireda Custom: alphabetical sort, case-insensitive
    list.sort((a, b) => (a.categoryName ?? '').toLowerCase().compareTo((b.categoryName ?? '').toLowerCase()));
    return list;
  }

  /// Check if user can post an ad (subscription validation)
  Future<bool> canPostAd() async {
    // Free ad listing enabled — no subscription needed
    if (Constant.freeAdListing) return true;

    final uid = FireStoreUtils.getCurrentUid();
    if (uid == null) {
      ShowToastDialog.showError("Please login to post an ad");
      return false;
    }

    // Check for active ad listing subscription
    final activeSub = await FireStoreUtils.getActiveSubscription(uid, 'ad_listing');

    if (activeSub == null) {
      // No active subscription — redirect to purchase
      ShowToastDialog.showWarning("You need a subscription to post ads");
      Get.to(() => const SubscriptionsView());
      return false;
    }

    // Check ad limit using real active ad count
    if (activeSub.isItemLimitUnlimited != true) {
      final activeAdCount = await FireStoreUtils.countUserActiveAds(uid);
      if (activeAdCount >= (activeSub.adLimit ?? 0)) {
        ShowToastDialog.showError("You have $activeAdCount active ads (limit: ${activeSub.adLimit}). Please upgrade your plan.");
        Get.to(() => const SubscriptionsView());
        return false;
      }
    }

    return true;
  }
}