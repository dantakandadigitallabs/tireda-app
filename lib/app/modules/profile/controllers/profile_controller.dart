import 'dart:developer' as developer;

import 'package:eSellify/app/constant/constants.dart';
import 'package:eSellify/app/models/user_subscription_model.dart';
import 'package:eSellify/utils/fire_store_utils.dart';
import 'package:get/get.dart';

import '../../../models/user_model.dart' show UserModel;

class ProfileController extends GetxController {
  RxBool isLoading = true.obs;
  Rx<UserModel> userModel = UserModel().obs;

  Rx<UserSubscriptionModel?> activeAdListingSub = Rx<UserSubscriptionModel?>(null);
  Rx<UserSubscriptionModel?> activeFeaturedSub = Rx<UserSubscriptionModel?>(null);
  RxBool isLoadingPlan = true.obs;

  @override
  void onInit() {
    getData();
    super.onInit();
  }

  Future<void> getData() async {
    try {
      if (FireStoreUtils.getCurrentUid() != null) {
        final user = await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid().toString());
        if (user != null) {
          userModel.value = user;
        }
        await _loadActivePlan();
        update();
      }
    } catch (e, stack) {
      developer.log("Error getting user data: $e", stackTrace: stack);
    } finally {
      isLoading.value = false;
    }
  }

  // Tireda Custom: lightweight standalone fetch — deliberately not routed
  // through SubscriptionsController so Profile doesn't depend on its lifecycle.
  Future<void> _loadActivePlan() async {
    final uid = FireStoreUtils.getCurrentUid();
    if (uid == null) return;
    isLoadingPlan.value = true;
    try {
      activeAdListingSub.value = await FireStoreUtils.getActiveSubscription(uid, 'ad_listing');
      activeFeaturedSub.value = await FireStoreUtils.getActiveSubscription(uid, 'featured_ads');
    } catch (e, stack) {
      developer.log("Error getting active plan: $e", stackTrace: stack);
    } finally {
      isLoadingPlan.value = false;
    }
  }

  bool get showPlanCard => !(Constant.freeAdListing && Constant.freeAdFeaturing);

  // Tireda Custom: prefers a genuinely paid & active plan; falls back to
  // Ad Listing (even if free) per product decision, then Featured Ads.
  UserSubscriptionModel? get displayedSub {
    final ad = activeAdListingSub.value;
    final feat = activeFeaturedSub.value;
    final adPaid = ad != null && ad.isActive && (ad.price ?? 0) > 0;
    final featPaid = feat != null && feat.isActive && (feat.price ?? 0) > 0;
    if (adPaid) return ad;
    if (featPaid) return feat;
    return ad ?? feat;
  }

  String get displayedPlanName {
    final sub = displayedSub;
    if (sub == null) return 'Free';
    return sub.packageName?.isNotEmpty == true ? sub.packageName! : 'Free';
  }

  bool get isDisplayedPlanFree => displayedSub == null || (displayedSub!.price ?? 0) <= 0;

  // Tireda Custom: drives the plan-card pill button label/behavior.
  String get planCtaLabel => isDisplayedPlanFree ? 'Upgrade' : 'Manage';
}